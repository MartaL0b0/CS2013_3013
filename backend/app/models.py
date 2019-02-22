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

    def return_username(self, out_data, out):
        # Return the username for the user who submitted the form
        out_data['submitter'] = out.user.username

    def return_unix_time(self, out_data, out):
        # Return the time as a Unix timestamp
        out_data['time'] = int(out.time.timestamp())

    @marshmallow.post_dump(pass_many=True, pass_original=True)
    def dump_tweaks(self, out_data, many, out):
        tweaks = [self.return_username, self.return_unix_time]
        if not many:
            if not out:
                return out_data

            for t in tweaks:
                t(out_data, out)

            return out_data

        for i, d in enumerate(out_data):
            if not d:
                continue

            for t in tweaks:
                t(d, out[i])

        return out_data

    @marshmallow.post_dump
    def stringify_amount(self, out_data):
        # Stringify the amount to ensure fixed point precision
        # Python's JSON serializer will refuse to serialize Decimal anyway
        if 'amount' in out_data:
            out_data['amount'] = str(out_data['amount'])

    @marshmallow.post_dump
    def stringify_payment_type(self, out_data):
        # Python's JSON serializer will not serialize enums
        if 'payment_method' in out_data:
            out_data['payment_method'] = out_data['payment_method'].name

    @marshmallow.pre_load
    def parse_unix_time(self, in_data):
        if 'time' in in_data:
            t = in_data['time']
            if type(t) != int or t < 0:
                raise ValidationError('time must be a valid Unix timestamp')

            # Marshmallow expects DateTime fields to be in ISO string form
            in_data['time'] = datetime.utcfromtimestamp(t).isoformat()

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
