#!/bin/sh
# main application entrypoint

# python output buffering breaks stdout in docker
export PYTHONUNBUFFERED=1

# start the background tasks worker
celery worker --workdir /opt/app --app briefthreat.celery --loglevel info &

# start the periodic task scheduler (delayed to ensure db is ready)
rm -f /tmp/celerybeat.pid
sleep 5 && celery beat --workdir /opt/app --app briefthreat.celery --loglevel info --pidfile /tmp/celerybeat.pid --schedule /tmp/celerybeat-schedule &

if [ "$FLASK_ENV" == "development" ]; then
	# use flask debug server in development
	exec python /opt/app/briefthreat.py
else
	# use gunicorn in production
	exec gunicorn --workers $GUNICORN_WORKERS --bind :8080 --chdir /opt/app briefthreat:app
fi
