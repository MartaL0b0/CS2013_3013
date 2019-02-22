from flask import request
from flask_restful import Resource
from flask_jwt_extended import jwt_required, current_user

from models import *
from . import json_required
from .auth import admin_required

class Manage(Resource):
    # GET -> Return the list of forms
    @admin_required
    def get(self):
        return forms_schema.jsonify(Form.query.all())

    # POST -> Submit a new form
    @json_required
    @jwt_required
    def post(self):
        # Validate and deserialize input
        new_form = Form()
        try:
            new_form_schema.load(request.r_data, instance=new_form)
        except ValidationError as err:
            return err.messages, 422

        new_form.submitter = current_user.id
        new_form.resolved = False
        db.session.add(new_form)
        db.session.commit()
        return None, 204

    # PATCH -> Update a form
    @json_required
    @jwt_required
    def patch(self):
        # Validate and deserialize input
        update_req = Form()
        try:
            edit_form_schema.load(request.r_data, instance=update_req)
        except ValidationError as err:
            return err.messages, 422

        to_update = Form.find_by_id(update_req.id)
        old = full_form_schema.jsonify(to_update)
        if not to_update:
            return {'message': 'Form with id {} does not exist'.format(update_req.id)}, 400

        if not current_user.is_admin and to_update.user != current_user:
            return {'message': ('You must have either submitted form {} '
                    'or be an admin to update it').format(to_delete.id)}, 401

        to_update.update(update_req)
        db.session.commit()
        return old

    # DELETE -> Remove a form from the database (by its ID)
    @json_required
    @jwt_required
    def delete(self):
        # Validate and deserialize input
        del_req = Form()
        try:
            delete_form_schema.load(request.r_data, instance=del_req)
        except ValidationError as err:
            return err.messages, 422

        to_delete = Form.find_by_id(del_req.id)
        if not to_delete:
            return {'message': 'Form with id {} does not exist'.format(del_req.id)}, 400

        if not current_user.is_admin and to_delete.user != current_user:
            return {'message': ('You must have either submitted form {} '
                    'or be an admin to delete it').format(to_delete.id)}, 401

        db.session.delete(to_delete)
        db.session.commit()
        return full_form_schema.jsonify(to_delete)
