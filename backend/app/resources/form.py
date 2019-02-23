from flask import request, current_app, render_template
from flask_restful import Resource
from flask_jwt_extended import jwt_required, current_user
import flask_emails as mail

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

        for admin in User.query.filter(User.is_admin == True):
            # Create a token the admin can use to mark the form as resolved
            # This can be validated by its signature
            resolve_info = UIResolve(username=admin.username, form_id=new_form.id)
            token = ui_resolve_schema.dump(resolve_info).data
            resolve_link = '{}/resolve?token={}'.format(current_app.config['PUBLIC_URL'], token)

            notification = mail.Message(
                    mail_from=(current_app.config['EMAIL_NAME'], current_app.config['EMAIL_FROM']),
                    subject='Form no. {}'.format(new_form.id),
                    text=render_template('new_form.txt', form=new_form, admin=admin, resolve_link=resolve_link),
                    html=render_template('new_form.html', form=new_form, admin=admin, resolve_link=resolve_link),
                    )
            notification.config.smtp_options['fail_silently'] = False
            notification.send(to=(admin.full_name, admin.email))

        return {'id': new_form.id}

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

        db.session.merge(update_req)
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

def do_resolve(to_resolve):
    to_resolve.resolved_at = datetime.utcnow()
    db.session.commit()

    notification = mail.Message(
            mail_from=(current_app.config['EMAIL_NAME'], current_app.config['EMAIL_FROM']),
            subject="Form resolved",
            text=render_template('notification.txt', form=to_resolve),
            html=render_template('notification.html', form=to_resolve),
            )
    notification.config.smtp_options['fail_silently'] = False
    notification.send(to=(to_resolve.user.full_name, to_resolve.user.email))

class Resolution(Resource):
    @json_required
    @admin_required
    def put(self):
        resolve_req = Form()
        try:
            resolve_form_schema.load(request.r_data, instance=resolve_req)
        except ValidationError as err:
            return err.messages, 422

        to_resolve = Form.find_by_id(resolve_req.id)
        if not to_resolve:
            return {'message': 'Form with id {} does not exist'.format(resolve_req.id)}, 400

        if to_resolve.resolved_at != None:
            return {'message': 'Form {} is already resolved'.format(to_resolve.id)}, 400

        do_resolve(to_resolve)
        return full_form_schema.jsonify(to_resolve)

def init_app(app):
    @app.route("/resolve")
    def ui_resolve_form():
        # Deserialize and validate token from request params
        try:
            resolve_params = ui_resolve_schema.load(request.args).data
        except ValidationError as ex:
            message = ex.messages['_schema'][0] if '_schema' in ex.messages else ex
            return render_template('422.html', message=message), 422

        to_resolve = Form.find_by_id(resolve_params['form_id'])
        if to_resolve.resolved_at != None:
            return render_template('400.html', message='Form {} has already been resolved.'.format(to_resolve.id)), 400

        do_resolve(to_resolve)
        return render_template('resolve_success.html', form=to_resolve)
