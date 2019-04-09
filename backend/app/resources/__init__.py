from functools import wraps

from jwt.exceptions import PyJWTError
from flask import request, jsonify
import flask_restful
from flask_jwt_extended.exceptions import JWTExtendedException
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

class Api(flask_restful.Api):
    def error_router(self, orig_handler, e):
        # We don't want JWT exceptions to show up as Internal Server Errors!
        if isinstance(e, PyJWTError) or isinstance(e, JWTExtendedException):
            return orig_handler(e)

        return super(Api, self).error_router(orig_handler, e)

def json_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        json = request.get_json()
        if not json:
            return {'message': 'No input data provided'}, 400

        request.r_data = json
        return f(*args, **kwargs)

    return decorated_function
