from celery import Celery

import flask_emails as mail

# We want certain tasks to run in the background
# (so they don't block request handlers for too long)

def init_app(app):
    global celery
    celery = Celery(
        app.import_name,
        backend=app.config['CELERY_RESULT_BACKEND'],
        broker=app.config['CELERY_BROKER_URL']
    )
    celery.conf.update(app.config)

    # Tasks will always run with Flask context for convenience
    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask

    # Dynamically decorate the task functions
    global send_email
    send_email = celery.task(send_email)

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
