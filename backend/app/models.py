from datetime import datetime
from enum import Enum

from passlib.hash import pbkdf2_sha256 as sha256
from email_validator import validate_email, EmailNotValidError, EmailUndeliverableError
import sqlalchemy
import marshmallow
from marshmallow import ValidationError
from marshmallow_sqlalchemy import field_for
from itsdangerous import URLSafeSerializer, URLSafeTimedSerializer, BadSignature, BadData

from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_jwt_extended import decode_token

db = SQLAlchemy()
validation = Marshmallow()

def init_app(app):
    db.init_app(app)

    # Use Flask's secret key to sign our resolution tokens
    # The salt is a public value, but should be different for each type of token to prevent re-use
    form_resolve_signer = URLSafeSerializer(app.config['SECRET_KEY'], salt='form-resolution')
    pw_reset_signer = URLSafeTimedSerializer(app.config['SECRET_KEY'], salt='password-reset')

    ui_resolve_schema.itsd_signer = form_resolve_signer
    ui_pw_reset_schema.itsd_signer = pw_reset_signer
    ui_pw_reset_schema.itsd_max_age = app.config['PW_RESET_WINDOW']

class DumpTweaksMixin:
    def __init__(self):
        self._tweaks = []

    @marshmallow.post_dump(pass_many=True, pass_original=True)
    def _dump_tweaks(self, out_data, many, out):
        if not many:
            if not out:
                return out_data

            for t in self._tweaks:
                t(out_data, out)

            return out_data

        for i, d in enumerate(out_data):
            if not d:
                continue

            for t in self._tweaks:
                t(d, out[i])

        return out_data

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(128), unique=True, nullable=False)
    email = db.Column(db.String(128), unique=True, nullable=False)
    first_name = db.Column(db.String(64), nullable=False)
    last_name = db.Column(db.String(64))
    password = db.Column(db.String(128))
    registration_time = db.Column(db.DateTime, nullable=False)
    is_admin = db.Column(db.Boolean, nullable=False)
    current_pw_token = db.Column(db.Integer, nullable=False)
    revoked_tokens = db.relationship('RevokedToken', backref='user')
    forms = db.relationship('Form', backref='user')

    @classmethod
    def find_by_username(cls, username):
        return cls.query.filter_by(username=username).first()

    @classmethod
    def find_by_email(cls, email):
        return cls.query.filter_by(email=email).first()

    def verify_password(self, password):
        if not password or not self.password:
            return False
        return sha256.verify(password, self.password)

    @property
    def full_name(self):
        if self.last_name != None:
            return '{} {}'.format(self.first_name, self.last_name)

        return self.first_name

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


class PaymentType(Enum):
    cash = 1
    cheque = 2
class Form(db.Model):
    __tablename__ = 'forms'

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

    def get_changes(self):
        # Find what has changed in this object's history
        changed = set()
        old = Form()
        new = Form()
        for attr in sqlalchemy.inspect(self).attrs:
            if attr.history.has_changes():
                # Enum processing is done later in SQLAlchemy later apparently...
                if attr.key == 'payment_method':
                    if attr.history.deleted[0].name == attr.history.added[0]:
                        continue

                    changed.add(attr.key)
                    old.payment_method = attr.history.deleted[0]
                    new.payment_method = PaymentType[attr.history.added[0]]
                    continue

                changed.add(attr.key)
                old.__dict__[attr.key] = attr.history.deleted[0]
                new.__dict__[attr.key] = attr.history.added[0]

        return changed, new, old

class RevokedTokenSchema(validation.ModelSchema):
    class Meta:
        model = RevokedToken

    # We need access to this field after deserialization!
    username = field_for(User, 'username', dump_only=False)

    @marshmallow.pre_load
    def extract_jti(self, token):
        # Convert the token's dict to one that looks like our schema
        token['username'] = token['identity']
        del token['identity']
        token['expiry'] = datetime.utcfromtimestamp(token['exp']).isoformat()
        del token['exp']

        return token

class FormSchema(validation.ModelSchema, DumpTweaksMixin):
    class Meta:
        model = Form
        exclude = ['user', 'submitter']

    # We need to make the id required
    id = marshmallow.fields.Int(required=True)

    def __init__(self, *args, **kwargs):
        validation.ModelSchema.__init__(self, *args, **kwargs)
        DumpTweaksMixin.__init__(self)
        self._tweaks = [self.return_username, self.return_unix_time]
        self.unix_fields = ['time', 'resolved_at']

    def return_username(self, out_data, out):
        # Return the username for the user who submitted the form
        out_data['submitter'] = out.user.username

    def return_unix_time(self, out_data, out):
        # Return the time as a Unix timestamp
        for f in self.unix_fields:
            d = out.__dict__
            if d[f]:
                out_data[f] = int(d[f].timestamp())

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

class UserSchema(validation.ModelSchema, DumpTweaksMixin):
    class Meta:
        model = User
        # Users shouldn't be able to supply a list of revoked tokens
        dump_only = ["revoked_tokens"]

    revoked_tokens = validation.Nested(RevokedTokenSchema, many=True)

    def __init__(self, *args, **kwargs):
        validation.ModelSchema.__init__(self, *args, **kwargs)
        DumpTweaksMixin.__init__(self)
        self._tweaks = [self.return_unix_time]

    @marshmallow.pre_load
    def hash_password(self, in_data):
        if 'registration_time' in in_data and isinstance(in_data['registration_time'], datetime):
            # Marshmallow expects DateTime fields to be in ISO string form
            in_data['registration_time'] = in_data['registration_time'].isoformat()
        if 'password' in in_data:
            # We don't want to store the password in plain text!
            in_data['password'] = sha256.hash(in_data['password'])
        return in_data

    @marshmallow.pre_load
    def validate_email(self, in_data):
        if 'email' in in_data:
            try:
                result = validate_email(in_data['email'], check_deliverability=True)
                in_data['email'] = result['email']
            except (EmailNotValidError, EmailUndeliverableError) as ex:
                raise ValidationError(str(ex))

    def return_unix_time(self, out_data, out):
        # Return the registration time as a Unix timestamp
        out_data['registration_time'] = int(out.registration_time.timestamp())

class ItsDangerousSchema(marshmallow.Schema):
    def __init__(self, signer, *args, max_age=None, **kwargs):
        marshmallow.Schema.__init__(self, *args, **kwargs)
        self.itsd_signer = signer
        self.itsd_max_age = max_age

    @marshmallow.pre_load
    def deserialize(self, in_data):
        if not 'token' in in_data:
            raise ValidationError('No token provided')

        try:
            # Validate and deserialize the token
            if self.itsd_max_age:
                result = self.itsd_signer.loads(in_data['token'], max_age=self.itsd_max_age)
            else:
                result = self.itsd_signer.loads(in_data['token'])
        except (BadSignature, BadData) as ex:
            raise ValidationError(str(ex))

        return result

    @marshmallow.post_dump
    def serialize(self, out_data):
        # Return a signed token as the serialized result
        return self.itsd_signer.dumps(out_data)

class UIResolveSchema(ItsDangerousSchema):
    username = marshmallow.fields.Str(required=True)
    form_id = marshmallow.fields.Integer(required=True)

    def __init__(self, *args, **kwargs):
        ItsDangerousSchema.__init__(self, None, *args, **kwargs)

class UIPasswordResetSchema(ItsDangerousSchema):
    username = marshmallow.fields.Str(required=True)
    token_id = marshmallow.fields.Integer(required=True)

    def __init__(self, *args, **kwargs):
        ItsDangerousSchema.__init__(self, None, *args, **kwargs)

    @marshmallow.post_load
    def ensure_latest_token(self, data):
        user = User.find_by_username(data['username'])
        # We increment this value every time a new reset request is made,
        # invalidating the previous one(s)
        if data['token_id'] != user.current_pw_token:
            raise ValidationError('This token has already been used')

        return data

full_user_schema = UserSchema(strict=True)
new_user_schema = UserSchema(strict=True, only=['username', 'email', 'is_admin', 'first_name', 'last_name'], partial=['last_name'])
login_schema = UserSchema(strict=True, only=['username', 'password'])
change_pw_schema = UserSchema(strict=True, only=['password'])
change_access_schema = UserSchema(strict=True, only=['username', 'is_admin'], partial=['is_admin'])
user_info_schema = UserSchema(strict=True, exclude=['password', 'current_pw_token', 'revoked_tokens'])
pw_reset_schema = UserSchema(strict=True, only=['username'])

revoked_token_schema = RevokedTokenSchema(strict=True)
ui_pw_reset_schema = UIPasswordResetSchema(strict=True)

full_form_schema = FormSchema(strict=True)
forms_schema = FormSchema(strict=True, many=True)
new_form_schema = FormSchema(strict=True, exclude=['id', 'resolved_at'])
delete_form_schema = FormSchema(strict=True, only=['id'])
edit_form_schema = FormSchema(strict=True, exclude=['resolved_at'], partial=('time', 'customer_name', 'course', 'payment_method', 'amount', 'receipt'))
resolve_form_schema = FormSchema(strict=True, only=['id', 'resolved_at'])
ui_resolve_schema = UIResolveSchema(strict=True)
