#!/bin/sh
# main application entrypoint

# python output buffering breaks stdout in docker
export PYTHONUNBUFFERED=1

if [ "$FLASK_ENV" == "development" ]; then
	# use flask debug server in development
	exec python /opt/app/briefthreat.py
else
	# use gunicorn in production
	gunicorn --workers $GUNICORN_WORKERS --bind :8080 --chdir /opt/app --user nobody --group nogroup briefthreat:app &

	# in production periodically clean up stale unapproved registrations
	while true; do
		sleep 120
		curl -s -X DELETE http://localhost:8080/api/v1/auth/cleanup > /dev/null
	done
fi
