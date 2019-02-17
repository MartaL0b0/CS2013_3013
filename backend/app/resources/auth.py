from flask import request, jsonify
from marshmallow import ValidationError
from flask_restful import Resource, reqparse
from flask_jwt_extended import *

from models import *

jwt = JWTManager()

# Error handlers which produces values consistent with the rest of the API
@jwt.claims_verification_failed_loader
def e_claims_verification_failed():
    return jsonify({'message': 'User claims verification failed'}), 400
@jwt.expired_token_loader
def e_expired_token():
    return jsonify({'message': 'Token has expired'}), 401
@jwt.invalid_token_loader
def e_invalid_token(e):
    return jsonify({'message': e}), 422
@jwt.needs_fresh_token_loader
def e_needs_fresh_token():
    return jsonify({'message': 'Fresh token required'}), 401
@jwt.revoked_token_loader
def e_revoked_token():
    return jsonify({'message': 'Token has been revoked'}), 401
@jwt.unauthorized_loader
def e_unauthorized(e):
    return jsonify({'message': e}), 401
@jwt.user_loader_error_loader
def e_user_loader(identity):
    return jsonify({'message': 'User {} specified by token does not exist'.format(identity)}), 401

# A token's revocation is determined by its presence (or lack thereof) in the database
@jwt.token_in_blacklist_loader
def is_token_revoked(decoded_token):
    return RevokedToken.is_revoked(decoded_token['jti'])

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
        raise Exception('test')

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
