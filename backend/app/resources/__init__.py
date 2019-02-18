from functools import wraps

from flask import request, jsonify

def json_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        json = request.get_json()
        if not json:
            return {'message': 'No input data provided'}, 400

        request.r_data = json
        return f(*args, **kwargs)

    return decorated_function
