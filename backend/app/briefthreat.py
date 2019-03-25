import os
from os import environ
from datetime import datetime
import json

import passlib.pwd
from werkzeug.contrib.fixers import ProxyFix
from flask import Flask, Response, request, jsonify, render_template
import redis
from healthcheck import HealthCheck

import tasks
from resources import Api, limiter, auth, form
import models
from models import db, validation, User, full_user_schema

app = Flask(__name__)
# Make sure request.remote_addr represents the real client IP
app.wsgi_app = ProxyFix(app.wsgi_app)

# Configuration is provided through environment variables by Docker Compose
app.config.update({
    'TEST_MODE': 'TEST_MODE' in environ and environ['TEST_MODE'].lower() == 'true',
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SECRET_KEY': environ['FLASK_SECRET'],
    'SERVER_NAME': environ['PUBLIC_HOST'],
    'PREFERRED_URL_SCHEME': 'https',
    'ROOT_EMAIL': environ['ROOT_EMAIL'],
    'EMAIL_NAME': environ['EMAIL_NAME'],
    'EMAIL_FROM': environ['EMAIL_FROM'],
    'JWT_SECRET_KEY': environ['JWT_SECRET'],
    'JWT_BLACKLIST_ENABLED': True,
    'JWT_BLACKLIST_TOKEN_CHECKS': ['access', 'refresh'],
    'JWT_ACCESS_TOKEN_EXPIRES': int(environ['JWT_ACCESS_EXPIRY']),
    'JWT_REFRESH_TOKEN_EXPIRES': int(environ['JWT_REFRESH_EXPIRY']),
    'PW_RESET_WINDOW': int(environ['PW_RESET_WINDOW']),
    'RATELIMIT_ENABLED': True if environ['FLASK_ENV'] == 'production' else False,
    'RATELIMIT_DEFAULT': environ['RATELIMIT_DEFAULT'],
    'CLEANUP_ENABLED': True if environ['FLASK_ENV'] == 'production' else False,
    'CLEANUP_INTERVAL': int(environ['CLEANUP_INTERVAL']),
    # We use Redis since there will be load balancing between workers in production,
    # so there must be synchronisation between them!
    # Database 0 is for ratelimiting
    'RATELIMIT_STORAGE_URL': 'redis://redis:6379/0',
    # Database 1 is for background tasks
    'CELERY_RESULT_BACKEND': 'redis://redis:6379/1',
    'CELERY_BROKER_URL': 'redis://redis:6379/1',
})
if app.config['TEST_MODE']:
    app.config.update({
        'SQLALCHEMY_DATABASE_URI': 'sqlite:////tmp/test.db',
    })
else:
    app.config.update({
        'SQLALCHEMY_DATABASE_URI': 'mysql+mysqlconnector://{user}:{password}@{host}/{database}'.format(
            user = environ['MYSQL_USER'],
            password = environ['MYSQL_PASSWORD'],
            host = environ['MYSQL_HOST'],
            database = environ['MYSQL_DATABASE']
        ),
        'EMAIL_HOST': environ['SMTP_HOST'],
        'EMAIL_PORT': 587,
        'EMAIL_HOST_USER': environ['SMTP_USER'],
        'EMAIL_HOST_PASSWORD': environ['SMTP_PASSWORD'],
        'EMAIL_USE_TLS': True,
        'EMAIL_TIMEOUT': 5,
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
tasks.init_app(app)

from tasks import celery

def db_ok():
    return User.query.count() >= 0, "database ok"
def tasks_ok():
    # Convert to int, Redis always returns bytes
    succeeded = int(celery_redis.get('succeeded'))
    # Redis returns bytes...
    already_failed = set(map(lambda id: id.decode('utf8'), celery_redis.lrange('failed', 0, -1)))
    new_failed = []
    for meta_key in map(lambda key: key.decode('utf8'), celery_redis.scan_iter(match='celery-task-meta-*')):
        # HACK: Celery can't deserialize SQLAlchemy exceptions correctly
        # (https://github.com/celery/celery/issues/5057)
        # So we deserialize the JSON ourselves (instead of using AsyncResult)
        meta = json.loads(celery_redis.get(meta_key).decode('utf8'))
        task_id = meta['task_id']
        status = meta['status']
        if status in tasks.SUCCESS_STATES:
            succeeded += 1
            celery_redis.delete(meta_key)
        elif status in tasks.EXCEPTION_STATES and not task_id in already_failed:
            new_failed.append(task_id)

    celery_redis.set('succeeded', succeeded)
    if new_failed:
        # Store the newly failed tasks in Redis
        celery_redis.lpush('failed', *new_failed)
    failed = list(already_failed) + new_failed
    return not failed, {'succeeded': succeeded, 'failed': failed}

# Set up health check, don't cache results
health = HealthCheck(app, '/health', success_ttl=None, failed_ttl=None)
health.add_check(db_ok)
health.add_check(tasks_ok)

# Mount our API endpoints
api.add_resource(auth.Registration, '/auth/register')
api.add_resource(auth.Login, '/auth/login')
api.add_resource(auth.Token, '/auth/token')
api.add_resource(auth.Access, '/auth/access')
api.add_resource(form.Manage, '/form')
api.add_resource(form.Resolution, '/form/resolve')

# UI routes
auth.add_ui_routes(app)
form.add_ui_routes(app)

if app.config['TEST_MODE']:
    @app.route('/lastmail')
    def lastmail():
        with open('/tmp/lastmail.json') as in_:
            last = in_.read()
        os.remove('/tmp/lastmail.json')
        return Response(last, content_type='application/json')

@app.before_first_request
def init_db():
    # Create the tables (does nothing if they already exist)
    db.create_all()

    # Create the default `root` user if they don't exist
    root = User.find_by_username('root')
    if not root:
        root = User()
        password = 'root' if app.config['TEST_MODE'] else passlib.pwd.genword(entropy=256)
        full_user_schema.load({
            'username': 'root',
            'email': app.config['ROOT_EMAIL'],
            'first_name': 'Administrator',
            'password': password,
            'registration_time': datetime.utcnow(),
            'current_pw_token': 0,
            'is_admin': True
        }, instance=root)

        db.session.add(root)
        db.session.commit()

        print('**** ROOT USER CREATED ****')
        print('PASSWORD: {}'.format(password))

@app.before_first_request
def connect_redis():
    # So we can list the completed Celery tasks
    global celery_redis
    celery_redis = redis.Redis(host='redis', db=1)
    if not celery_redis.exists('succeeded'):
        celery_redis.set('succeeded', '0')

if __name__ == "__main__":
    # If we are started directly, run the Flask development server
    app.run(host='0.0.0.0', port=8080)
