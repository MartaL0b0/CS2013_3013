FROM python:3-alpine

COPY requirements.txt app.sh /opt/
RUN pip install -r /opt/requirements.txt && mkdir /opt/app

ENV GUNICORN_WORKERS=4
EXPOSE 8080/tcp
CMD [ "/opt/app.sh" ]
