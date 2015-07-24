FROM samos123/drupal:latest

RUN apt-get -q update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install wget patch

ADD tripal_chado_install /scripts/setup.d/50tripal_chado_install
