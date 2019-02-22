from datetime import datetime
from enum import Enum

from passlib.hash import pbkdf2_sha256 as sha256
import marshmallow
from marshmallow import ValidationError
from marshmallow_sqlalchemy import field_for

from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_jwt_extended import decode_token

db = SQLAlchemy()
validation = Marshmallow()

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(128), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)
    registration_time = db.Column(db.DateTime, nullable=False)
    is_approved = db.Column(db.Boolean, nullable=False)
    is_admin = db.Column(db.Boolean, nullable=False)
    revoked_tokens = db.relationship('RevokedToken', backref='user')
    forms = db.relationship('Form', backref='user')

    @classmethod
    def find_by_username(cls, username):
        return cls.query.filter_by(username=username).first()

    def verify_password(self, password):
        return sha256.verify(password, self.password)

class RevokedToken(db.Model):
    __tablename__ = 'revoked_tokens'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(128), db.ForeignKey('users.username'), nullable=False)
    # JTI is the unique identifier of a JWT
    jti = db.Column(db.String(64), nullable=False)
    expiry = db.Column(db.DateTime, nullable=False)

    @classmethod
    def is_revoked(cls, jti):
        query = cls.query.filter_by(jti=jti).first()
        return bool(query)

class Form(db.Model):
    __tablename__ = 'forms'

    class PaymentType(Enum):
        cash = 1
        cheque = 2

    id = db.Column(db.Integer, primary_key=True)
    submitter = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    time = db.Column(db.DateTime, nullable=False)
    customer_name = db.Column(db.String(128), nullable=False)
    course = db.Column(db.String(256), nullable=False)
    payment_method = db.Column(db.Enum(PaymentType), nullable=False)
    amount = db.Column(db.Numeric(precision=16, scale=2), nullable=False)
    receipt = db.Column(db.String(128), nullable=False)
    resolved_at = db.Column(db.DateTime)

    @classmethod
    def find_by_id(cls, id):
        return cls.query.get(id)

    def update(self, other):
        if other.time != None:
            self.time = other.time
        if other.customer_name != None:
            self.customer_name = other.customer_name
        if other.course != None:
            self.course = other.course
        if other.payment_method != None:
            self.payment_method = other.payment_method
        if other.amount != None:
            self.amount = other.amount
        if other.receipt != None:
            self.receipt = other.receipt
        if other.resolved_at != None:
            self.resolved_at = other.resolved_at

class RevokedTokenSchema(validation.ModelSchema):
    class Meta:
        model = RevokedToken

    # We need access to this field after deserialization!
    username = field_for(User, 'username', dump_only=False)

    @marshmallow.pre_load
    def extract_jti(self, in_data):
        if not 'token' in in_data:
            raise ValidationError('No token provided')

        # Load the username and jti from the token we have been asked to revoke
        try:
            token = decode_token(in_data['token'])
        except Exception as ex:
            raise ValidationError('Invalid token provided: {}'.format(ex))

        in_data['username'] = token['identity']
        in_data['jti'] = token['jti']
        in_data['expiry'] = datetime.utcfromtimestamp(token['exp']).isoformat()
        del in_data['token']

        return in_data

class FormSchema(validation.ModelSchema):
    class Meta:
        model = Form
        exclude = ['user', 'submitter']

    @marshmallow.post_dump(pass_many=True, pass_original=True)
    def add_submitter_name(self, out_data, many, out):
        # Return the username for the user who submitted the form
        if not many:
            out_data = [out_data]
            out = [out]

        for i, d in enumerate(out_data):
            d['submitter'] = out[i].user.username

        return out_data

    @marshmallow.post_dump
    def stringify_amount(self, out_data):
        # Stringify the amount to ensure fixed point precision
        # Python's JSON serializer will refuse to serialize Decimal anyway
        out_data['amount'] = str(out_data['amount'])

    @marshmallow.post_dump
    def stringify_payment_type(self, out_data):
        # Python's JSON serializer will not serialize enums
        out_data['payment_method'] = out_data['payment_method'].name

class UserSchema(validation.ModelSchema):
    class Meta:
        model = User
        # Users shouldn't be able to supply a list of revoked tokens
        dump_only = ["revoked_tokens"]

    revoked_tokens = validation.Nested(RevokedTokenSchema, many=True)
    forms = validation.Nested(FormSchema, many=True)

    @marshmallow.pre_load
    def hash_password(self, in_data):
        if 'registration_time' in in_data and isinstance(in_data['registration_time'], datetime):
            # Marshmallow expects DateTime fields to be in ISO string form
            in_data['registration_time'] = in_data['registration_time'].isoformat()
        if 'password' in in_data:
            # We don't want to store the password in plain text!
            in_data['password'] = sha256.hash(in_data['password'])
        return in_data

full_user_schema = UserSchema(strict=True)
new_user_schema = UserSchema(strict=True, only=['username', 'password'])
change_pw_schema = UserSchema(strict=True, only=['password'])
change_access_schema = UserSchema(strict=True, exclude=['id', 'password', 'registration_time'], partial=['is_approved', 'is_admin'])

revoked_token_schema = RevokedTokenSchema(strict=True)

full_form_schema = FormSchema(strict=True)
forms_schema = FormSchema(strict=True, many=True)
new_form_schema = FormSchema(strict=True, exclude=['id', 'resolved_at'])
delete_form_schema = FormSchema(strict=True, only=['id'])
edit_form_schema = FormSchema(strict=True, exclude=['resolved_at'], partial=True)
