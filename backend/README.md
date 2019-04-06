# Backend
Flask, MySQL (MariaDB) and Nginx-based REST API (with Redis and [Celery](http://www.celeryproject.org/)) in Docker Compose

# Installation
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

- `MYSQL_DATA` specifies the directory on your system where the MySQL data should be stored.
- `MYSQL_ROOT_PASSWORD` is the password which will be set for the new MySQL instance's root user.
- `MYSQL_USER` is the name of the MySQL user that will be created and used for the application.
- `MYSQL_PASSWORD` is the password which will be created for the above user.
- `REDIS_DATA` is the directory where persistent Redis data should be stored
- `FLASK_ENV` decides whether the app should run in production or development mode. In development mode the Flask debugger will be enabled, allowing you instantly see new changes in the app without having to restart it. Detailed stack traces will also be shown in your browser when exceptions occur.
- `FLASK_SECRET` is the secret key which is issued to sign tokens for email notification links.
- `PUBLIC_HOST` is the hostname and (optionally) port which the server should be publically accessible by - this is used for generating email links.
- `ROOT_EMAIL` is the email address which will be used for automatic first-run registration of the root user (not to be confused with the MySQL root user)
- `EMAIL_NAME` and `EMAIL_FROM` are _metadata_ only values used in email headers for emails sent by the system
- `SMTP_*` are credentials for an SMTP server that will be used to send emails
`openssl req -x509 -subj '/CN=localhost' -newkey rsa:4096 -keyout key.pem -nodes -out certificate.crt -days 365`
Note that the filenames must be `key.pem` for the private key and `certificate.crt` for the certificate.
- The `JWT_*_EXPIRY` variables set how long the JWT access and refresh tokens should be valid for (in seconds)
- `PW_RESET_WINDOW` is the amount of time (in seconds) for which a password reset token will be valid
- The format for the `RATELIMIT_*` options can be found in the [documentation for `flask-limiter`](https://flask-limiter.readthedocs.io/en/stable/#rate-limit-string-notation)
- `CLEANUP_INTERVAL` specifies the interval for which the cleanup task should be executed. Note that this will only run in production.
- `NGINX_HOST` is the public hostname through which the server will be accessible (no port part)
- `NGINX_HTTP_PORT` / `NGINX_HTTPS_PORT` are the ports which will be bound publicly for external access to the backend
- `SSL_CERTS` specifies the directory on your system where SSL certificates for the main Nginx server (which proxies to the main service) can be found. You can generate your own self-signed certificate with the following command:

To start the app, just run `docker-compose up`. Hit CTRL+C to shut it down.

Note: If the Dockerfiles change, you can run `docker-compose up --build` to ensure they're re-built.

# Deployment tips
After following the above steps, you should have a development environment which you can manually start / stop. Note that you should tweak some of the values in your `.env` to be more suitable for production, notably:
- All of the passwords / secrets should use secure random values, for example using the command `pwgen 64 1`
- `FLASK_ENV` should be set to `production`
- `PUBLIC_HOST` and `NGINX_HOST` should be real domains
- The Nginx ports should probably be 80 and 443 for HTTP and HTTPS respectively
- Real SSL certificates should be used in place of self-signed ones, you can obtain these for free from [Let's Encrypt](https://letsencrypt.org/)

After this, you can put the following into `/etc/systemd/system/briefthreat.service` (only on systemd-based systems of course!):
```ini
[Unit]
Description=BriefThreat backend application
After=docker.service
Requires=docker.service

[Service]
Type=simple
workingDirectory=/path/to/backend
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
```

Then, simply do `sudo systemctl start briefthreat.service`. You can also run `sudo systemctl enable briefthreat.service` to have it run automatically at boot.

# Testing
This project makes use of [Tavern](https://taverntesting.github.io/) for testing (including mocked emails).

To run the tests, install Docker and Docker Compose (as above). You can then do `./run_tests.sh`. A temporary test environment will be created automatically (no `.env` file required).
