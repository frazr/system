## Introduction
This is a Dockerfile to build a container image for nginx, php-fpm & mysql, with the ability to pull website code from git. The container also has the ability to update templated files with variables passed to docker in order to update your settings. There is also support for lets encrypt SSL support.

## Building
docker build -t oas/helpav1 github.com/frazr/system

## Running
docker run -p80:80 -p2222:22 --name helpa oas/helpav1

## Creating user & domain
new [user] [domain]

### Git repository
The source files for this project can be found here: [https://github.com/ngineered/nginx-php-fpm](https://github.com/ngineered/nginx-php-fpm)

If you have any improvements please submit a pull request.
### Docker hub repository
The Docker hub build can be found here: [https://registry.hub.docker.com/u/richarvey/nginx-php-fpm/](https://registry.hub.docker.com/u/richarvey/nginx-php-fpm/)
## Versions
| Tag | Nginx | PHP | Alpine |
|-----|-------|-----|--------|
| latest | 1.10.1 | 5.6.23 | 3.4 |
| php5 | 1.10.1 | 5.6.23 | 3.4 |
| php7 | 1.10.1 | 7.0.8 | 3.4 |
