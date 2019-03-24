from flask import request, current_app, render_template, jsonify, url_for
from flask_restful import Resource
from flask_jwt_extended import jwt_required, current_user

from models import *
from . import json_required
from .auth import admin_required
import tasks

def get_resolve_link(username, form_id):
    # Create a token the admin can use to mark the form as resolved
    # This can be validated by its signature
    token = ui_resolve_schema.dump({'username': username, 'form_id': form_id}).data
    return url_for('ui_resolve_form', token=token, _external=True)

class Manage(Resource):
    # GET -> Return the list of forms
    @jwt_required
    def get(self):
        if current_user.is_admin:
            # Show all forms to admins
            return forms_schema.jsonify(Form.query.all())
        else:
            # Only show forms submitted by non-admins
            return forms_schema.jsonify(Form.query.filter(Form.user == current_user))

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
            resolve_link = get_resolve_link(admin.username, new_form.id)

            tasks.send_email.delay(
                    from_=(current_app.config['EMAIL_NAME'], current_app.config['EMAIL_FROM']),
                    to=(admin.full_name, admin.email),
                    subject='Form no. {}'.format(new_form.id),
                    text=render_template('new_form.txt', form=new_form, admin=admin, resolve_link=resolve_link),
                    html=render_template('new_form.html', form=new_form, admin=admin, resolve_link=resolve_link)
                    )

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
        if not to_update:
            return {'message': 'Form {} does not exist'.format(update_req.id)}, 400

        if to_update.resolved_at != None:
            return {'message': 'Form {} has been resolved, it can no longer be edited'.format(to_update.id)}, 400

        if not current_user.is_admin and to_update.user != current_user:
            return {'message': ('You must have either submitted form {} '
                    'or be an admin to update it').format(to_update.id)}, 401

        to_update.get_changes()
        old_res = full_form_schema.jsonify(to_update)
        db.session.merge(update_req)
        changed, new, old = to_update.get_changes()
        db.session.commit()

        # We should notify admins _only_ when a form has changed
        if len(changed) == 0:
            return None, 204

        for admin in User.query.filter(User.is_admin == True):
            resolve_link = get_resolve_link(admin.username, to_update.id)

            tasks.send_email.delay(
                    from_=(current_app.config['EMAIL_NAME'], current_app.config['EMAIL_FROM']),
                    to=(admin.full_name, admin.email),
                    subject='Form no. {}'.format(to_update.id),
                    text=render_template('edited_form.txt', form=to_update, changed=changed, old=old, new=new, admin=admin, editor=current_user, resolve_link=resolve_link),
                    html=render_template('edited_form.html', form=to_update, changed=changed, old=old, new=new, admin=admin, editor=current_user, resolve_link=resolve_link)
                    )

        return old_res

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
            return {'message': 'Form {} does not exist'.format(del_req.id)}, 400

        if not current_user.is_admin and to_delete.user != current_user:
            return {'message': ('You must have either submitted form {} '
                    'or be an admin to delete it').format(to_delete.id)}, 401

        db.session.delete(to_delete)
        db.session.commit()
        return full_form_schema.jsonify(to_delete)

def do_resolve(to_resolve):
    to_resolve.resolved_at = datetime.utcnow()
    db.session.commit()

    tasks.send_email.delay(
            to=(to_resolve.user.full_name, to_resolve.user.email),
            from_=(current_app.config['EMAIL_NAME'], current_app.config['EMAIL_FROM']),
            subject='Form no. {}'.format(to_resolve.id),
            text=render_template('notification.txt', form=to_resolve),
            html=render_template('notification.html', form=to_resolve)
            )

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
            return {'message': 'Form {} does not exist'.format(resolve_req.id)}, 400

        if to_resolve.resolved_at != None:
            return {'message': 'Form {} is already resolved'.format(to_resolve.id)}, 400

        do_resolve(to_resolve)
        return full_form_schema.jsonify(to_resolve)

def add_ui_routes(app):
    @app.route("/resolve")
    def ui_resolve_form():
        # Deserialize and validate token from request params
        try:
            resolve_params = ui_resolve_schema.load(request.args).data
        except ValidationError as ex:
            message = ex.messages['_schema'][0] if '_schema' in ex.messages else ex
            return render_template('422.html', message=message), 422

        to_resolve = Form.find_by_id(resolve_params['form_id'])
        if not to_resolve:
            return render_template('400.html', message='Form {} does not exist. It may have been deleted.'.format(resolve_params['form_id'])), 400

        if to_resolve.resolved_at != None:
            return render_template('400.html', message='Form {} has already been resolved.'.format(to_resolve.id)), 400

        do_resolve(to_resolve)
        return render_template('resolve_success.html', form=to_resolve)
