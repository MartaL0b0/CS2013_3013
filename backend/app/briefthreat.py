import os

from marshmallow import ValidationError
from sqlalchemy.exc import IntegrityError
from flask import Flask, request, jsonify
from flask_restful import Api
from flask_marshmallow import Marshmallow
from flask_jwt_extended import JWTManager

import models, resources

app = Flask(__name__)

# Configuration is provided through environment variables by Docker Compose
app.config.update({
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SQLALCHEMY_DATABASE_URI': 'mysql+mysqlconnector://{user}:{password}@{host}/{database}'.format(
        user = os.environ['MYSQL_USER'],
        password = os.environ['MYSQL_PASSWORD'],
        host = os.environ['MYSQL_HOST'],
        database = os.environ['MYSQL_DATABASE']
    ),
    'SECRET_KEY': os.environ['FLASK_SECRET'],
    'JWT_SECRET_KEY': os.environ['JWT_SECRET'],
    'JWT_BLACKLIST_ENABLED': True,
    'JWT_BLACKLIST_TOKEN_CHECKS': ['access', 'refresh']
})

api = Api(app)
models.db.init_app(app)
validation = Marshmallow(app)
jwt = JWTManager(app)

# Mount our API endpoints
api.add_resource(resources.UserRegistration, '/registration')
api.add_resource(resources.UserLogin, '/login')
api.add_resource(resources.UserLogoutAccess, '/logout/access')
api.add_resource(resources.UserLogoutRefresh, '/logout/refresh')
api.add_resource(resources.TokenRefresh, '/token/refresh')
api.add_resource(resources.AllUsers, '/users')
api.add_resource(resources.SecretResource, '/secret')

@app.before_first_request
def create_tables():
    # Create the tables (does nothing if they already exist)
    models.db.create_all()

# Logout functionality. Tokens cannnot be removed as they are valid until expired
# Instead we add them to a blacklist and check against it.
# This is done for access and refresh tokens.
@jwt.token_in_blacklist_loader
def check_if_token_in_blacklist(decrypted_token):
    jti = decrypted_token['jti']
    return models.RevokedTokenModel.is_jti_blacklisted(jti)

if __name__ == "__main__":
    # If we are started directly, run the Flask development server
    app.run(host='0.0.0.0', port=8080)
