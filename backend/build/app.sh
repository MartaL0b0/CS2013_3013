#!/bin/sh

if [ "$FLASK_ENV" == "development" ]; then
        exec python /opt/app/briefthreat.py
else
        exec gunicorn --workers $GUNICORN_WORKERS --bind :8080 --chdir /opt/app --user nobody --group nogroup wsgi:app
fi
