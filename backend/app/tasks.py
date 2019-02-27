from datetime import datetime, timedelta

from celery import Celery
from celery.utils.log import get_task_logger

from flask import current_app
import flask_emails as mail

from models import db, User, RevokedToken

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
    # Clean up registrations that have gone unapproved for more than `REGISTRATION_WINDOW`
    cutoff = datetime.utcnow() - timedelta(seconds=current_app.config['REGISTRATION_WINDOW'])
    reg_removed = User.query.filter(User.registration_time < cutoff, User.is_approved == False).delete()

    # Clean up revoked tokens that have expired
    tokens_removed = RevokedToken.query.filter(RevokedToken.expiry < datetime.utcnow()).delete()

    db.session.commit()

    if reg_removed > 0:
        logger.info('cleaned up {} stale registrations'.format(reg_removed))
    if tokens_removed > 0:
        logger.info('cleaned up {} expired revoked tokens'.format(tokens_removed))
