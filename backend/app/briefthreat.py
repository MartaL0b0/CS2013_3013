from os import environ
from datetime import datetime

import passlib.pwd
from werkzeug.contrib.fixers import ProxyFix
from flask import Flask, request, jsonify, render_template
from healthcheck import HealthCheck

from resources import Api, limiter, auth, form
import models
from models import db, validation, User, full_user_schema

app = Flask(__name__)
# Make sure request.remote_addr represents the real client IP
app.wsgi_app = ProxyFix(app.wsgi_app)

# Configuration is provided through environment variables by Docker Compose
app.config.update({
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SQLALCHEMY_DATABASE_URI': 'mysql+mysqlconnector://{user}:{password}@{host}/{database}'.format(
        user = environ['MYSQL_USER'],
        password = environ['MYSQL_PASSWORD'],
        host = environ['MYSQL_HOST'],
        database = environ['MYSQL_DATABASE']
    ),
    'SECRET_KEY': environ['FLASK_SECRET'],
    'PUBLIC_URL': environ['PUBLIC_URL'],
    'ROOT_EMAIL': environ['ROOT_EMAIL'],
    'EMAIL_NAME': environ['EMAIL_NAME'],
    'EMAIL_FROM': environ['EMAIL_FROM'],
    'EMAIL_HOST': environ['SMTP_HOST'],
    'EMAIL_PORT': 587,
    'EMAIL_HOST_USER': environ['SMTP_USER'],
    'EMAIL_HOST_PASSWORD': environ['SMTP_PASSWORD'],
    'EMAIL_USE_TLS': True,
    'EMAIL_TIMEOUT': 5,
    'JWT_SECRET_KEY': environ['JWT_SECRET'],
    'JWT_BLACKLIST_ENABLED': True,
    'JWT_BLACKLIST_TOKEN_CHECKS': ['access', 'refresh'],
    'JWT_ACCESS_TOKEN_EXPIRES': int(environ['JWT_ACCESS_EXPIRY']),
    'JWT_REFRESH_TOKEN_EXPIRES': int(environ['JWT_REFRESH_EXPIRY']),
    'REGISTRATION_WINDOW': int(environ['REGISTRATION_WINDOW']),
    'RATELIMIT_ENABLED': True if environ['FLASK_ENV'] == 'production' else False,
    'RATELIMIT_DEFAULT': environ['RATELIMIT_DEFAULT'],
    # We use memcached since there will be load balancing between workers in production,
    # so there must be synchronisation between them!
    'RATELIMIT_STORAGE_URL': 'memcached://memcache:11211'
})

@app.errorhandler(404)
def not_found(e):
    if request.path.startswith('/api/v1'):
        return jsonify({'message': 'Not found'}), 404

    return render_template('404.html'), 404

api = Api(app, prefix='/api/v1')
models.init_app(app)
auth.jwt.init_app(app)
validation.init_app(app)
limiter.init_app(app)

def db_ok():
    return User.query.count() >= 0, "database ok"
health = HealthCheck(app, '/health')
health.add_check(db_ok)

# Mount our API endpoints
api.add_resource(auth.Registration, '/auth/register')
api.add_resource(auth.Login, '/auth/login')
api.add_resource(auth.Token, '/auth/token')
api.add_resource(auth.Access, '/auth/access')
api.add_resource(auth.Cleanup, '/auth/cleanup')
api.add_resource(form.Manage, '/form')
api.add_resource(form.Resolution, '/form/resolve')

# UI routes
form.init_app(app)

@app.before_first_request
def create_tables():
    # Create the tables (does nothing if they already exist)
    db.create_all()

    # Create the default `root` user if they don't exist
    root = User.find_by_username('root')
    if not root:
        root = User()
        password = passlib.pwd.genword(entropy=256)
        full_user_schema.load({
            'username': 'root',
            'email': app.config['ROOT_EMAIL'],
            'first_name': 'Administrator',
            'password': password,
            'registration_time': datetime.utcnow(),
            'is_approved': True,
            'is_admin': True
        }, instance=root)

        db.session.add(root)
        db.session.commit()

        print('**** ROOT USER CREATED ****')
        print('PASSWORD: {}'.format(password))

if __name__ == "__main__":
    # If we are started directly, run the Flask development server
    app.run(host='0.0.0.0', port=8080)
