FROM fhsinchy/php-nginx-base:php8.1.3-fpm-nginx1.20.2-alpine3.15

# set composer related environment variables
ENV PATH="/composer/vendor/bin:$PATH" \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_VENDOR_DIR=/var/www/app/vendor \
    COMPOSER_HOME=/composer

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --ansi --version --no-interaction

# install application dependencies
# copy application code
WORKDIR /var/www/app
COPY . .
RUN composer install
#RUN cd /var/www/app && composer install --no-scripts --no-autoloader --ansi --no-interaction
RUN cd /var/www/app && composer update --no-scripts
# RUN cd /var/www/app && composer dump-autoload -o \
#     && chown -R :www-data /var/www/app \
#     && chmod -R 775 /var/www/app/storage /var/www/app/bootstrap/cache
#RUN  composer install --ignore-platform-reqs

# add custom php-fpm pool settings, these get written at entrypoint startup
ENV FPM_PM_MAX_CHILDREN=20 \
    FPM_PM_START_SERVERS=2 \
    FPM_PM_MIN_SPARE_SERVERS=1 \
    FPM_PM_MAX_SPARE_SERVERS=3

# set application environment variables
ENV APP_NAME="Question Board" \
    APP_ENV=production \
    APP_DEBUG=false

# copy entrypoint files
COPY ./docker/docker-php-* /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-php-entrypoint
RUN dos2unix /usr/local/bin/docker-php-entrypoint-dev

# copy nginx configuration
COPY ./docker/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/default.conf /etc/nginx/conf.d/default.conf


RUN cd /var/www/app  && chown -R :www-data /var/www/app \
    && chmod -R 775 /var/www/app/storage /var/www/app/bootstrap/cache



# run supervisor

RUN chmod +x /usr/local/bin/docker-php-entrypoint
RUN chmod +x /usr/local/bin/docker-php-entrypoint-dev
RUN chmod 777 .
EXPOSE 80
# ENTRYPOINT [ "/usr/local/bin/docker-php-entrypoint-dev" ]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
