FROM php:7.1-apache

# Install packages and PHP-extensions
RUN apt-get -q update && \
    mkdir -p /usr/share/man/man1 /usr/share/man/man7 && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install \
    file libfreetype6 libjpeg62 libpng16-16 libpq-dev libx11-6 libxpm4 \
    postgresql-client wget patch cron logrotate git nano python python-requests python-setuptools \
    memcached libmemcached11 libmemcachedutil2 gpg dirmngr ca-certificates && \
    BUILD_DEPS="libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng-dev libxpm-dev re2c zlib1g-dev libmemcached-dev python-pip python-dev libpq-dev"; \
    DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install $BUILD_DEPS \
 && docker-php-ext-configure gd \
        --with-jpeg-dir=/usr/lib/x86_64-linux-gnu --with-png-dir=/usr/lib/x86_64-linux-gnu \
        --with-xpm-dir=/usr/lib/x86_64-linux-gnu --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
 && docker-php-ext-install gd mbstring pdo_pgsql zip \
 && pip install chado==2.2.5 tripal==3.2 \
 && pecl install memcached \
 && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $BUILD_DEPS \
 && rm -rf /var/lib/apt/lists/*
# && pecl install uploadprogress # not yet compatible with php7 on PECL

ENV TINI_VERSION v0.9.0
RUN set -x \
    && curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" -o /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini

ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Provide compatibility for images depending on previous versions
RUN ln -s /var/www/html /app
# Update apache2 configuration for drupal
RUN a2enmod rewrite && a2enmod proxy && a2enmod proxy_http

# Compile a php7 compatible version of uploadprogress module
RUN cd /tmp && git clone https://github.com/php/pecl-php-uploadprogress.git && cd pecl-php-uploadprogress && phpize && ./configure && make && make install && cd /

# Download Drupal from ftp.drupal.org
ENV DRUPAL_VERSION=7.64
ENV DRUPAL_TARBALL_MD5=bbb3c4d8c2cba35c48380d34f122f750
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

RUN wget https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins110/chado-1.31-tripal.sql.gz -O /chado-master-tripal.sql.gz \
    && wget --no-check-certificate https://drupal.org/files/drupal.pgsql-bytea.27.patch -O /drupal.pgsql-bytea.27.patch

WORKDIR html

# Install elasticsearch php library (required by tripal_elasticsearch)
RUN cd /var/www/html/sites/all/libraries/\
    && mkdir elasticsearch-php \
    && cd elasticsearch-php \
    && composer require "elasticsearch/elasticsearch:~5.0" \
    && cd /var/www/html/

ENV BASE_URL_PATH="/tripal" \
    GALAXY_SHARED_DIR="/tripal-data/" \
    ENABLE_DRUPAL_CACHE=1 \
    ENABLE_OP_CACHE=1 \
    ENABLE_MEMCACHE=1 \
    ENABLE_CRON_JOBS=0 \
    TRIPAL_BASE_CODE_GIT="https://github.com/tripal/tripal.git[@3b3ddebf8fb420a0cc77cc6572a9dcbba4377a7c]" \
    TRIPAL_GIT_CLONE_MODULES="https://github.com/abretaud/tripal_rest_api.git[@cb1d52ffed0b8a5c1ac189b41c729c8ad93b1c21] https://github.com/tripal/tripal_elasticsearch.git[@bac9c5d35f4c38e906fe48f55064906af8ea029a] https://github.com/tripal/trpdownload_api.git" \
    TRIPAL_DOWNLOAD_MODULES="queue_ui tripal_analysis_interpro-7.x-2.x-dev tripal_analysis_blast-7.x-2.x-dev tripal_analysis_go-7.x-2.x-dev" \
    TRIPAL_ENABLE_MODULES="tripal_genetic tripal_natural_diversity tripal_phenotype tripal_project tripal_pub tripal_stock tripal_analysis_blast tripal_analysis_interpro tripal_analysis_go tripal_rest_api tripal_elasticsearch trpdownload_api"

RUN repo_url=`echo $TRIPAL_BASE_CODE_GIT | sed 's/\(.\+\)\[@\w\+\]/\1/'`; \
    rev=`echo $TRIPAL_BASE_CODE_GIT | sed 's/.\+\[@\(\w\+\)\]/\1/'`; \
    git clone $repo_url /var/www/html/sites/all/modules/tripal; \
    if [ "$repo_url" != "$rev" ]; then \
        cd /var/www/html/sites/all/modules/tripal; \
        git reset --hard $rev; \
        cd /var/www/html/; \
    fi;

# Pre download all default modules
RUN drush pm-download ctools views libraries services ultimate_cron memcache ${TRIPAL_BASE_MODULE} \
    $TRIPAL_DOWNLOAD_MODULES \
    && for repo in $TRIPAL_GIT_CLONE_MODULES; do \
        repo_url=`echo $repo | sed 's/\(.\+\)\[@\w\+\]/\1/'`; \
        rev=`echo $repo | sed 's/.\+\[@\(\w\+\)\]/\1/'`; \
        module_name=`basename $repo_url .git`; \
        git clone $repo_url /var/www/html/sites/all/modules/$module_name; \
        if [ "$repo_url" != "$rev" ]; then \
            cd /var/www/html/sites/all/modules/$module_name; \
            git reset --hard $rev; \
            cd /var/www/html/sites/all/modules/; \
        fi; \
    done

RUN cd /var/www/html/sites/all/modules/views \
    && patch -p1 < ../tripal/tripal_views/views-sql-compliant-three-tier-naming-1971160-30.patch \
    && cd /var/www/html/

# Add custom functions
ADD search.sql /search.sql

# Add PHP-settings
ADD php-conf.d/ $PHP_INI_DIR/conf.d/

# Add logrotate conf
ADD logrotate.d/tripal /etc/logrotate.d/

# copy sites/default's defaults
ADD etc/tripal/settings.php /etc/tripal/settings.php

# Add README.md, entrypoint-script and scripts-folder
ADD entrypoint.sh README.md  /
ADD /scripts/ /scripts/

ADD tripal_apache.conf /etc/apache2/conf-enabled/tripal_apache.conf

CMD ["/entrypoint.sh"]
