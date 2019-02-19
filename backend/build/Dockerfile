FROM python:3-alpine

COPY requirements.txt /opt/
RUN apk --no-cache add curl && \
	pip install -r /opt/requirements.txt && \
	mkdir /opt/app

COPY app.sh /opt/

ENV GUNICORN_WORKERS=4
EXPOSE 8080/tcp
HEALTHCHECK --start-period=5s --interval=10s --retries=5 \
	CMD curl -f http://localhost:8080/health || exit 1
CMD [ "/opt/app.sh" ]
