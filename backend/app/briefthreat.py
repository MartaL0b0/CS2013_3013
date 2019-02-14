import os

from marshmallow import ValidationError
from sqlalchemy.exc import IntegrityError
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow

app = Flask(__name__)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+mysqlconnector://{user}:{password}@{host}/{database}'.format(
        user = os.environ['MYSQL_USER'],
        password = os.environ['MYSQL_PASSWORD'],
        host = os.environ['MYSQL_HOST'],
        database = os.environ['MYSQL_DATABASE']
)

db = SQLAlchemy(app)
validation = Marshmallow(app)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
class UserSchema(validation.ModelSchema):
    class Meta:
        model = User

user_schema = UserSchema(strict=True)
users_schema = UserSchema(many=True, strict=True)

@app.route('/users', methods=['POST'])
def make_user():
    json = request.get_json()
    if not json:
        return jsonify({'message': 'No input data provided'}), 400

    # Validate and deserialize input
    new_user = User()
    try:
        user_schema.load(json, instance=new_user)
    except ValidationError as err:
        return jsonify(err.messages), 422

    db.session.add(new_user)
    try:
        db.session.commit()
    except IntegrityError as err:
        return jsonify({ 'message': 'User already exists' }), 400

    return user_schema.jsonify(new_user)

@app.route('/users', methods=['GET'])
def list_users():
    return users_schema.jsonify(User.query.all())

@app.route('/')
def hello_world():
    return jsonify({ 'message': 'Hello, World!' })

if __name__ == "__main__":
    db.create_all()
    app.run(host='0.0.0.0', port=8080)
