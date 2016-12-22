FROM php:apache
MAINTAINER Eric Rasche <esr@tamu.edu>

ENV TINI_VERSION v0.9.0
RUN set -x \
    && curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" -o /usr/local/bin/tini \
    && curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini.asc" -o /usr/local/bin/tini.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
    && gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
    && rm -r "$GNUPGHOME" /usr/local/bin/tini.asc \
    && chmod +x /usr/local/bin/tini

ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Provide compatibility for images depending on previous versions
RUN ln -s /var/www/html /app
# Update apache2 configuration for drupal
RUN a2enmod rewrite && a2enmod proxy && a2enmod proxy_http

# Install packages and PHP-extensions
RUN apt-get -q update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install \
    file libfreetype6 libjpeg62 libpng12-0 libpq-dev libx11-6 libxpm4 \
    postgresql-client wget patch cron logrotate git python python-requests && \
    BUILD_DEPS="libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev libxpm-dev re2c zlib1g-dev python-pip python-dev libpq-dev"; \
    DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install $BUILD_DEPS \
 && docker-php-ext-configure gd \
        --with-jpeg-dir=/usr/lib/x86_64-linux-gnu --with-png-dir=/usr/lib/x86_64-linux-gnu \
        --with-xpm-dir=/usr/lib/x86_64-linux-gnu --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
 && docker-php-ext-install gd mbstring pdo_pgsql zip \
 && pip install chado tripal \
 && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $BUILD_DEPS \
 && rm -rf /var/lib/apt/lists/*
# && pecl install uploadprogress # not yet compatible with php7 on PECL

# Compile a php7 compatible version of uploadprogress module
RUN cd /tmp && git clone https://github.com/php/pecl-php-uploadprogress.git && cd pecl-php-uploadprogress && phpize && ./configure && make && make install && cd /

# Download Drupal from ftp.drupal.org
ENV DRUPAL_VERSION=7.53
ENV DRUPAL_TARBALL_MD5=4230279ecca4f0cde652a219e10327e7
WORKDIR /var/www
RUN rm -R html \
 && curl -OsS https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz \
 && echo "${DRUPAL_TARBALL_MD5}  drupal-${DRUPAL_VERSION}.tar.gz" | md5sum -c \
 && tar -xf drupal-${DRUPAL_VERSION}.tar.gz && rm drupal-${DRUPAL_VERSION}.tar.gz \
 && mv drupal-${DRUPAL_VERSION} html \
 && cd html \
 && rm [A-Z]*.txt install.php web.config sites/default/default.settings.php

# Install composer and drush by using composer
ENV COMPOSER_BIN_DIR=/usr/local/bin
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 && composer global require drush/drush:7.* \
 && drush cc drush \
 && mkdir /etc/drush && echo "<?php\n\$options['yes'] = TRUE;\n\$options['v'] = TRUE;\n" > /etc/drush/drushrc.php

RUN wget https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins90/chado-1.31-tripal.sql.gz -O /chado-master-tripal.sql.gz

# Add PHP-settings
ADD php-conf.d/ $PHP_INI_DIR/conf.d/

# Add logrotate conf
ADD logrotate.d/tripal /etc/logrotate.d/

# copy sites/default's defaults
WORKDIR html
ADD etc/tripal/settings.php /etc/tripal/settings.php

# Add README.md, entrypoint-script and scripts-folder
ADD entrypoint.sh README.md  /
ADD /scripts/ /scripts/

ADD tripal_apache.conf /etc/apache2/conf-enabled/tripal_apache.conf

ENV BASE_URL_PATH="/tripal"

ENV TRIPAL_GIT_CLONE_MODULES="https://github.com/abretaud/tripal_rest_api.git https://github.com/tripal/tripal_elasticsearch.git"
ENV TRIPAL_DOWNLOAD_MODULES="tripal_analysis_interpro-7.x-2.x-dev tripal_analysis_blast-7.x-2.x-dev tripal_analysis_go-7.x-2.x-dev"
ENV TRIPAL_ENABLE_MODULES="tripal_genetic tripal_natural_diversity tripal_phenotype tripal_project tripal_pub tripal_stock tripal_analysis_blast tripal_analysis_interpro tripal_analysis_go tripal_rest_api tripal_elasticsearch"

CMD ["/entrypoint.sh"]
