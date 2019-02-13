FROM python:3-alpine

COPY requirements.txt /opt/
RUN pip install -r /opt/requirements.txt

RUN mkdir /opt/app

ENV GUNICORN_WORKERS=4
EXPOSE 8080/tcp
CMD gunicorn --workers $GUNICORN_WORKERS --bind :8080 --chdir /opt/app --user nobody --group nogroup wsgi:app
