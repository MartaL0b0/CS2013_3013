FROM python:3.6-alpine

COPY requirements.txt /opt/
RUN apk --no-cache add curl libxml2 libxml2-dev libxslt libxslt-dev gcc musl-dev && \
	pip install -r /opt/requirements.txt && \
	apk del gcc musl-dev libxml2-dev libxslt-dev && \
	mkdir /opt/app

COPY app.sh /opt/

USER nobody:nogroup
ENV GUNICORN_WORKERS=4
EXPOSE 8080/tcp
HEALTHCHECK --start-period=5s --interval=10s --retries=5 \
	CMD curl -f http://localhost:8080/health -H "Host: $PUBLIC_HOST" || exit 1
CMD [ "/opt/app.sh" ]
