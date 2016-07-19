FROM samos123/drupal:latest

RUN a2enmod proxy && a2enmod proxy_http

#TODO: gpg verify
RUN apt-get -q update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install wget patch && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://cpt.tamu.edu/jenkins/job/Chado-Prebuilt-Schemas/19/artifact/compile-chado-schema/chado/default/chado-master-tripal.sql.gz -O /chado-master-tripal.sql.gz

ADD tripal_chado_install /scripts/setup.d/50tripal_chado_install

ADD tripal_apache.conf /etc/apache2/conf-enabled/tripal_apache.conf
