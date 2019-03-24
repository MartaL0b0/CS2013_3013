from datetime import datetime, timedelta

from celery import Celery
from celery.utils.log import get_task_logger
import celery.states as celery_states

from flask import current_app
import flask_emails as mail

from models import db, User, RevokedToken

EXCEPTION_STATES = celery_states.EXCEPTION_STATES
SUCCESS_STATES = celery_states.READY_STATES - EXCEPTION_STATES

# We want certain tasks to run in the background
# (so they don't block request handlers for too long)

def init_app(app):
    global celery
    celery = Celery(
        app.import_name,
        backend=app.config['CELERY_RESULT_BACKEND'],
        broker=app.config['CELERY_BROKER_URL']
    )

    # Tasks will always run with Flask context for convenience
    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask

    # Task logging
    global logger
    logger = get_task_logger(app.import_name)

    # Dynamically decorate the task functions
    global send_email, cleanup
    send_email = celery.task(send_email)
    cleanup = celery.task(cleanup)

    # Periodic task configuration
    if app.config['CLEANUP_ENABLED']:
        celery.add_periodic_task(app.config['CLEANUP_INTERVAL'], cleanup.s(), name='cleanup')

# The input must be JSON-serializable (since it will be sent to the Celery
# worker over the network)
def send_email(*, from_, to, subject, html, text=None):
    message = mail.Message(
            mail_from=from_,
            subject=subject,
            html=html,
            text=text
            )
    message.config.smtp_options['fail_silently'] = False
    message.send(to=to)

def cleanup():
    # Make sure the tables are initialized - we could be called
    # before @app.before_first_request
    db.create_all()

    # Clean up revoked tokens that have expired
    tokens_removed = RevokedToken.query.filter(RevokedToken.expiry < datetime.utcnow()).delete()

    db.session.commit()

    if tokens_removed > 0:
        logger.info('cleaned up {} expired revoked tokens'.format(tokens_removed))
