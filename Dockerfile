FROM ubuntu:16.04
MAINTAINER Maju Ansari <majua@mindfiresolutions.com>

# set some environment variables
ENV DEBIAN_FRONTEND noninteractive

# upgrade the container
RUN apt-get update && \
    apt-get upgrade -y

# install some prerequisites
RUN apt-get install -y software-properties-common curl build-essential \
    dos2unix gcc git libmcrypt4 libpcre3-dev memcached make python2.7-dev \
    python-pip re2c unattended-upgrades whois vim libnotify-bin nano wget \
    debconf-utils

# add some repositories

RUN apt-add-repository ppa:nginx/development -y && \
apt-add-repository ppa:chris-lea/redis-server -y && \
apt-add-repository ppa:ondrej/php -y && \
curl --silent --location https://deb.nodesource.com/setup_6.x | bash -  && \
apt-get update

# set the locale
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale  && \
    locale-gen en_US.UTF-8  && \
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# setup bash
COPY .bash_aliases /root

# install nginx
RUN apt-get install -y --force-yes nginx
COPY app.conf /etc/nginx/sites-available/
COPY fastcgi_params /etc/nginx/

RUN rm -rf /etc/nginx/sites-available/default && \
    rm -rf /etc/nginx/sites-enabled/default && \
    ln -fs "/etc/nginx/sites-available/app.conf" "/etc/nginx/sites-enabled/app.conf" && \
    sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf && \
    usermod -u 1000 www-data && \
    chown -Rf www-data.www-data /var/www/html/ && \
    sed -i -e"s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf
VOLUME ["/var/www/html/ascent"]
VOLUME ["/var/cache/nginx"]
VOLUME ["/var/log/nginx"]


# install php
RUN apt-get install -y --force-yes php7.1-cli php7.1-dev php-pgsql \
    php-sqlite3 php-gd php-apcu php-curl php7.1-mcrypt php-imap \
    php-mysql php-memcached php7.1-readline php-xdebug php-mbstring \
    php-xml php7.1-zip php7.1-intl php7.1-bcmath php-soap php7.1-fpm
RUN sed -i "/listen = .*/c\listen = [::]:9000" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/cli/php.ini && \
    sed -i -e "s/display_errors = .*/display_errors = On/" /etc/php/7.1/cli/php.ini && \
    sed -i -e "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini
RUN sed -i -e "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/display_errors = .*/display_errors = On/" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.1/fpm/pool.d/www.conf
RUN find /etc/php/7.1/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;
RUN phpdismod -s cli xdebug
RUN phpenmod mcrypt && \
    mkdir -p /run/php/ && chown -Rf www-data.www-data /run/php

# install sqlite
RUN apt-get install -y sqlite3 libsqlite3-dev

# install mysql
ADD mysql.sh /mysql.sh
RUN chmod +x /*.sh
RUN ./mysql.sh
VOLUME ["/var/lib/mysql"]

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    printf "\nPATH=\"~/.composer/vendor/bin:\$PATH\"\n" | tee -a ~/.bashrc


# install redis
RUN apt-get install -y redis-server memcached


# install beanstalkd
RUN apt-get install -y --force-yes beanstalkd && \
    sed -i "s/BEANSTALKD_LISTEN_ADDR.*/BEANSTALKD_LISTEN_ADDR=0.0.0.0/" /etc/default/beanstalkd && \
    sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd && \
    /etc/init.d/beanstalkd start

# install supervisor
RUN apt-get install -y supervisor && \
    mkdir -p /var/log/supervisor
VOLUME ["/var/log/supervisor"]


# install nodejs
RUN apt-get install -y nodejs

RUN /usr/bin/npm install -g gulp
RUN /usr/bin/npm install -g webpack
RUN /usr/bin/npm install -g bower
RUN /usr/bin/npm install -g yarn

# clean up our mess
RUN apt-get remove --purge -y software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/man/?? && \
    rm -rf /usr/share/man/??_*

# expose ports
EXPOSE 80 22 443 3306 6379
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# set container entrypoints
ENTRYPOINT ["/bin/bash","-c"]
CMD ["/usr/bin/supervisord"]
