from datetime import datetime

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
    registration_time = db.Column(db.DateTime(), nullable=False)
    is_approved = db.Column(db.Boolean, nullable=False)
    is_admin = db.Column(db.Boolean, nullable=False)
    revoked_tokens = db.relationship('RevokedToken', backref='user')

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

    @classmethod
    def is_revoked(cls, jti):
        query = cls.query.filter_by(jti=jti).first()
        return bool(query)

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
        del in_data['token']

        return in_data

class UserSchema(validation.ModelSchema):
    class Meta:
        model = User
        # Users shouldn't be able to supply a list of revoked tokens
        dump_only = ["revoked_tokens"]

    revoked_tokens = validation.Nested(RevokedTokenSchema, many=True)

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
change_access_schema = UserSchema(strict=True, exclude=['password', 'registration_time'], partial=['is_approved', 'is_admin'])

revoked_token_schema = RevokedTokenSchema(strict=True)
