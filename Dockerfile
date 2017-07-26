FROM centos:7
MAINTAINER Skiychan <dev@skiy.net>
##
# Nginx: 1.11.6
# PHP  : 7.0.15
##
#Install system library
#RUN yum update -y

ENV PHP_VERSION 7.0.15
ENV NGINX_VERSION 1.11.6

RUN yum install -y gcc \
        gcc-c++ \
        autoconf \
        automake \
        libtool \
        make \
        cmake \
        cronie && \
    yum clean all && \
    rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
    yum install -y zlib \
        zlib-devel \
        openssl \
        openssl-devel \
        pcre-devel \
        libxml2 \
        libxml2-devel \
        libcurl \
        libcurl-devel \
        libpng-devel \
        libjpeg-devel \
        freetype-devel \
        libmcrypt-devel \
        openssh-server \
        python-setuptools \
        libicu libicu-devel && \
    yum clean all && \
    groupadd -r www && \
    useradd -M -s /sbin/nologin -r -g www www && \
    mkdir -p /home/nginx-php && cd $_ && \
    curl -Lk http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
    curl -Lk http://php.net/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
    curl -Lk https://github.com/xdebug/xdebug/archive/XDEBUG_2_4_0RC3.tar.gz | gunzip | tar x -C /home/nginx-php && \
    curl -Lk php-redis.tar.gz https://github.com/phpredis/phpredis/archive/3.1.0.tar.gz | gunzip | tar x -C /home/nginx-php && \
    cd /home/nginx-php/nginx-$NGINX_VERSION && \
    ./configure --prefix=/usr/local/nginx \
        --user=www --group=www \
        --error-log-path=/var/log/nginx_error.log \
        --http-log-path=/var/log/nginx_access.log \
        --pid-path=/var/run/nginx.pid \
        --with-pcre \
        --with-http_ssl_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --with-http_gzip_static_module && \
    make && make install && \ 
    cd /home/nginx-php/php-$PHP_VERSION && \
    ./configure --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --with-config-file-scan-dir=/usr/local/php/etc/php.d \
        --with-fpm-user=www \
        --with-fpm-group=www \
        --with-mcrypt=/usr/include \
        --with-mysqli \
        --with-pdo-mysql \
        --with-openssl \
        --with-gd \
        --with-iconv \
        --with-zlib \
        --with-gettext \
        --with-curl \
        --with-png-dir \
        --with-jpeg-dir \
        --with-freetype-dir \
        --with-xmlrpc \
        --with-mhash \
        --enable-fpm \
        --enable-xml \
        --enable-shmop \
        --enable-sysvsem \
        --enable-inline-optimization \
        --enable-mbregex \
        --enable-mbstring \
        --enable-ftp \
        --enable-gd-native-ttf \
        --enable-mysqlnd \
        --enable-pcntl \
        --enable-sockets \
        --enable-zip \
        --enable-soap \
        --enable-session \
        --enable-opcache \
        --enable-bcmath \
        --enable-exif \
        --enable-fileinfo \
        --enable-intl \
        --disable-rpath \
        --enable-ipv6 \
        --disable-debug \
        --without-pear && \
    make && make install && \
    cd /home/nginx-php/xdebug-XDEBUG_2_4_0RC3 && \
    /usr/local/php/bin/phpize && \
        ./configure \
            --enable-xdebug \
            --with-php-config=/usr/local/php/bin/php-config && \
    make && \
    cp modules/xdebug.so /usr/local/php/lib/php/extensions/xdebug.so && \
    cd /home/nginx-php/phpredis-3.1.0 && \
    /usr/local/php/bin/phpize && \
        ./configure 
            --with-php-config=/usr/local/php/bin/php-config && \
    make && make install && \
    cp modules/redis.so /usr/local/php/lib/php/extensions/redis.so

ADD php.ini /usr/local/php/etc/php.ini

RUN	cd /home/nginx-php/php-$PHP_VERSION && \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf && \
    easy_install supervisor && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /var/run/sshd && \
    mkdir -p /var/run/supervisord

#Add supervisord conf
ADD supervisord.conf /etc/supervisord.conf

#Remove zips
RUN cd / && rm -rf /home/nginx-php

#Create web folder
VOLUME ["/data/www", "/usr/local/nginx/conf/ssl", "/usr/local/nginx/conf/vhost", "/usr/local/php/etc/php.d"]
ADD index.php /data/www/index.php

ADD xdebug.ini /usr/local/php/etc/php.d/xdebug.ini
ADD redis.ini /usr/local/php/etc/php.d/redis.ini

#Update nginx config
ADD nginx.conf /usr/local/nginx/conf/nginx.conf

#Start
ADD start.sh /start.sh
RUN chmod +x /start.sh

#Set port
EXPOSE 80 443 9000

#Start it
ENTRYPOINT ["/start.sh"]

#Start web server
#CMD ["/bin/bash", "/start.sh"]
