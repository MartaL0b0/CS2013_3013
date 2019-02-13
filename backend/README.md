# Backend
Flask, MySQL (MariaDB) and Nginx-based REST API in Docker Compose

# Development
You'll need an up-to-date version of [Docker](https://docs.docker.com/install/) and [Docker Compose](https://docs.docker.com/compose/install/) on your system to get started.

Once you have that, create a `.env` file in this directory. This file contains configuration specific to your installation or development environment. Example:
```
MYSQL_DATA=./data
MYSQL_ROOT_PASSWORD=lolbadpw
MYSQL_USER=briefthreat
MYSQL_PASSWORD=hunter2
MYSQL_DATABASE=briefthreat
FLASK_ENV=development
NGINX_HOST=localhost
SSL_CERTS=./ssl
```

- `MYSQL_DATA` specifies the directory on your system where the MySQL data should be stored (it should already exist).
- `FLASK_ENV` decides whether the app should run in production or development mode. In development mode the Flask debugger will be enabled, allowing you instantly see new changes in the app without having to restart it. Detailed stack traces will also be shown in your browser when exceptions occur.
- `SSL_CERTS` specifies the directory on your system where SSL certificates can be found. You can generate your own self-signed certificate with the following command:
`openssl req -x509 -subj '/CN=localhost' -newkey rsa:4096 -keyout key.pem -nodes -out certificate.crt -days 365`
Note that the filenames must be `key.pem` for the private key and `certificate.crt` for the certificate.

To start the app, just run `docker-compose up`. Hit CTRL+C to shut it down.
