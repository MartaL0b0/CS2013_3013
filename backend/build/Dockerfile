FROM python:3-alpine

COPY requirements.txt app.sh /opt/
RUN pip install -r /opt/requirements.txt && mkdir /opt/app

ENV GUNICORN_WORKERS=4
EXPOSE 8080/tcp
HEALTHCHECK --start-period=5s --interval=10s --retries=5 \
	CMD wget -O /dev/null http://localhost:8080/health || exit 1
CMD [ "/opt/app.sh" ]
