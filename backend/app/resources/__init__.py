from functools import wraps

from flask import request, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

def json_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        json = request.get_json()
        if not json:
            return {'message': 'No input data provided'}, 400

        request.r_data = json
        return f(*args, **kwargs)

    return decorated_function
