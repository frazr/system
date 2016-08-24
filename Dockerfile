FROM alpine:3.4

ENV php_conf /etc/php7/php.ini 
ENV fpm_conf /etc/php7/php-fpm.d/www.conf
ENV composer_hash e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae

RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && apk update && \
    apk add --no-cache bash \
    openssh-client \
    wget \
    nginx \
    supervisor \
    curl \
    git \
    php7-fpm \
    php7-pdo \
    php7-pdo_mysql \
    php7-mysqlnd \
    php7-mysqli \
    php7-mcrypt \
    php7-ctype \
    php7-zlib \
    php7-gd \
    php7-intl \
    php7-memcached \
    php7-sqlite3 \
    php7-pdo_pgsql \
    php7-pgsql \
    php7-xml \
    php7-xsl \
    php7-curl \
    php7-openssl \
    php7-iconv \
    php7-json \
    php7-phar \
    php5-soap \
    php7-dom \
    python \
    python-dev \
    py-pip \
    augeas-dev \
    openssl-dev \
    ca-certificates \
    dialog \
    gcc \
    musl-dev \
    linux-headers \
    libffi-dev &&\
    mkdir -p /etc/nginx && \
    mkdir -p /var/www/app && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    php7 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php7 -r "if (hash_file('SHA384', 'composer-setup.php') === '${composer_hash}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php7 composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php7 -r "unlink('composer-setup.php');" && \
    pip install -U certbot && \
    mkdir -p /etc/letsencrypt/webrootauth && \
    apk del gcc musl-dev linux-headers libffi-dev augeas-dev python-dev

RUN apk add --no-cache mysql mysql-client pwgen logrotate

# Editor
RUN apk add vim

# Copy our nginx config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx/restrictions /etc/nginx/restrictions
ADD conf/nginx/sites-enabled/default.conf /etc/nginx/sites-enabled/default.conf

# Nginx
RUN mkdir -p /etc/nginx/sites-available/ && \
mkdir -p /etc/nginx/sites-enabled/ && \
mkdir -p /etc/nginx/ssl/ && \
rm -Rf /var/www && \
mkdir -p /data/www_root

ADD conf/nginx/nginx-site.conf /etc/nginx/sites-available/default.conf
ADD conf/nginx/nginx-site-ssl.conf /etc/nginx/sites-available/default-ssl.conf
ADD conf/php-fpm.conf /etc/php7/php-fpm.conf
ADD conf/my.cnf /etc/mysql/my.cnf

# Php-fpm 
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} && \
sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" ${fpm_conf} && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} && \
sed -i -e "s/pm.max_children = 4/pm.max_children = 4/g" ${fpm_conf} && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} && \
sed -i -e "s/user = nobody/user = nginx/g" ${fpm_conf} && \
sed -i -e "s/group = nobody/group = nginx/g" ${fpm_conf} && \
sed -i -e "s/;listen.mode = 0660/listen.mode = 0666/g" ${fpm_conf} && \
sed -i -e "s/;listen.owner = nobody/listen.owner = nginx/g" ${fpm_conf} && \
sed -i -e "s/;listen.group = nobody/listen.group = nginx/g" ${fpm_conf} && \
sed -i -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" ${fpm_conf} && \
sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} &&\
ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini && \
find /etc/php7/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Use PHP7 
RUN mv /usr/bin/php /usr/bin/php5 && ln -s /usr/bin/php7 /usr/bin/php

RUN apk add --no-cache openssh php7-mbstring

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

# Add Scripts

ADD scripts/pull /usr/bin/pull
ADD scripts/push /usr/bin/push
ADD scripts/letsencrypt-setup /usr/bin/letsencrypt-setup
ADD scripts/letsencrypt-renew /usr/bin/letsencrypt-renew
ADD scripts/send-router-domains /usr/bin/send-router-domains
RUN chmod 755 /usr/bin/pull && \
    chmod 755 /usr/bin/push && \
    chmod 755 /usr/bin/letsencrypt-setup && \
    chmod 755 /usr/bin/letsencrypt-renew && \
    chmod 755 /usr/bin/send-router-domains

ADD conf/logrotate/nginx /etc/logrotate.d/nginx
ADD conf/logrotate/php-fpm7 /etc/logrotate.d/php-fpm7

RUN mkdir /var/run/mysql && \
    touch /var/run/mysql/mysqld.pid && \
    chown -R mysql. /var/run/mysql && \
    chmod 766 /var/run/mysql/mysqld.pid

# Copy in code
ADD src/ /data/www_root/

ADD conf/supervisord.conf /etc/supervisord.conf
ADD scripts/start.sh /start.sh
ADD scripts/new /usr/bin/new

RUN chmod 755 /usr/bin/new && \
    chmod 755 /start.sh
    
EXPOSE 443 80

CMD ["/start.sh"]
