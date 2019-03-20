# Backend
Flask, MySQL (MariaDB) and Nginx-based REST API in Docker Compose

# Development
You'll need an up-to-date version of [Docker](https://docs.docker.com/install/) and [Docker Compose](https://docs.docker.com/compose/install/) on your system to get started.

Once you have that, create a `.env` file in this directory. This file contains configuration specific to your installation or development environment. Example:
```
MYSQL_DATA=./data/mysql
MYSQL_ROOT_PASSWORD=lolbadpw
MYSQL_USER=briefthreat
MYSQL_PASSWORD=hunter2
MYSQL_DATABASE=briefthreat
REDIS_DATA=./data/redis
FLASK_ENV=development
FLASK_SECRET=thisshouldbesecret
PUBLIC_HOST=localhost
ROOT_EMAIL=test@example.com
EMAIL_NAME=BriefThreat
EMAIL_FROM=briefthreat@example.com
SMTP_HOST=mail.example.com
SMTP_USER=test
SMTP_PASSWORD=hunter2
JWT_SECRET=thisshouldalsobesecret
JWT_ACCESS_EXPIRY=900
JWT_REFRESH_EXPIRY=2592000
PW_RESET_WINDOW=86400
RATELIMIT_DEFAULT=1000/hour;10000/day
CLEANUP_INTERVAL=120
NGINX_HOST=localhost
NGINX_HTTP_PORT=8080
NGINX_HTTPS_PORT=8443
SSL_CERTS=./ssl
```

- `MYSQL_DATA` specifies the directory on your system where the MySQL data should be stored (it should already exist).
- `FLASK_ENV` decides whether the app should run in production or development mode. In development mode the Flask debugger will be enabled, allowing you instantly see new changes in the app without having to restart it. Detailed stack traces will also be shown in your browser when exceptions occur.
- `SSL_CERTS` specifies the directory on your system where SSL certificates can be found. You can generate your own self-signed certificate with the following command:
`openssl req -x509 -subj '/CN=localhost' -newkey rsa:4096 -keyout key.pem -nodes -out certificate.crt -days 365`
Note that the filenames must be `key.pem` for the private key and `certificate.crt` for the certificate.
- The `JWT_*_EXPIRY` variables set how long the JWT access and refresh tokens should be valid for (in seconds)
- The format for the `RATELIMIT_*` options can be found in the [documentation for `flask-limiter`](https://flask-limiter.readthedocs.io/en/stable/#rate-limit-string-notation)
- `EMAIL_NAME` and `EMAIL_FROM` set the _metadata_ which is placed in the email header; these have no bearing on the SMTP connection
- `CLEANUP_INTERVAL` specifies the interval for which the cleanup task should be executed. Note that this will only run in production.

To start the app, just run `docker-compose up`. Hit CTRL+C to shut it down.

Note: If the Docker images change, you can run `docker-compose up --build --force-recreate` to ensure they're re-built.
