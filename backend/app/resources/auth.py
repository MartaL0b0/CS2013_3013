from flask import request
from marshmallow import ValidationError
from flask_restful import Resource, reqparse
from flask_jwt_extended import *

from models import *

jwt = JWTManager()

class Registration(Resource):
    def post(self):
        json = request.get_json()
        if not json:
            return {'message': 'No input data provided'}, 400

        # Validate and deserialize input
        new_user = User()
        try:
            user_schema.load(json, instance=new_user)
        except ValidationError as err:
            return err.messages, 422

        if User.find_by_username(new_user.username):
            return {'message': 'User {} already exists'.format(new_user.username)}, 400

        # Save the new user into the database
        db.session.add(new_user)
        db.session.commit()

        # HTTP 204 is "No Content"
        return None, 204

class Login(Resource):
    def post(self):
        json = request.get_json()
        if not json:
            return {'message': 'No input data provided'}, 400

        # Validate and deserialize input
        login_user = User()
        try:
            user_schema.load(json, instance=login_user)
        except ValidationError as err:
            return err.messages, 422

        # Find the existing user and validate the input password against the saved hash
        user = User.find_by_username(login_user.username)
        if not user or not user.verify_password(json['password']):
            return {'message': 'Invalid credentials'}

        # Create a new refresh token (and access token for convenience)
        return {
            'refresh_token': create_refresh_token(identity=user.username),
            'access_token': create_access_token(identity=user.username)
        }

class Token(Resource):
    # POST -> Obtain a new access token with a refresh token
    @jwt_refresh_token_required
    def post(self):
        username = get_jwt_identity()
        return {'access_token': create_access_token(identity=username)}

    # DELETE -> Revoke a token (for logout)
    # Tokens cannot be removed as they are valid until expired.
    # Instead we add them to a revocation list and check against it.
    # This is done for access and refresh tokens.
    @jwt_required
    def delete(self):
        json = request.get_json()
        if not json:
            return {'message': 'No input data provided'}, 400
        username = get_jwt_identity()

        # Validate and deserialize input
        to_revoke = RevokedToken()
        try:
            revoked_token_schema.load(json, instance=to_revoke)
        except ValidationError as err:
            return err.messages, 422

        # Don't allow users to revoke tokens other than their own!
        if to_revoke.username != username:
            return {'message': 'You may only revoke your own tokens!'}

        existing = RevokedToken.is_revoked(to_revoke.jti)
        if existing:
            return {'message': 'This token is already revoked!'}, 400

        # Commit the revocation to the database
        db.session.add(to_revoke)
        db.session.commit()

        return None, 204

@jwt.token_in_blacklist_loader
def is_token_revoked(decoded_token):
    return RevokedToken.is_revoked(decoded_token['jti'])
