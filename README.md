# Tripal Docker Image

[![DOI](https://zenodo.org/badge/10899/erasche/docker-tripal.svg)](https://zenodo.org/badge/latestdoi/10899/erasche/docker-tripal)

![Tripal Logo](http://tripal.info/sites/default/files/TripalLogo_dark.png)

This image contains a ready-to-go installation of Tripal v2.1.

## Using the Container

We highly recommend using a `docker-compose.yml` to run your containers.

```yaml
version: "2"
services:
  tripal:
    image: erasche/tripal:latest
    links:
      - db:postgres
    volumes:
      - /var/www/html/sites
      - /var/www/private
    environment:
      UPLOAD_LIMIT: 20M
      MEMORY_LIMIT: 128M
      TRIPAL_DOWNLOAD_MODULES: "tripal_analysis_blast-7.x-2.x-dev"
      TRIPAL_GIT_CLONE_MODULES: "https://github.com/tripal/tripal_analysis_expression.git"
      TRIPAL_ADDITIONAL_MODULES: "tripal_analysis_blast tripal_analysis_expression tripal_analysis_intepro"
    ports:
      - "3000:80"
  db:
    image: erasche/chado:latest
    environment:
      - POSTGRES_PASSWORD=postgres
        # The default chado image would try to install the schema on first run,
        # we just want the GMOD tools to be available.
      - INSTALL_CHADO_SCHEMA=0
    volumes:
      - /var/lib/postgresql/9.4/
```

## Configuring the Container

By default, tripal should display properly by going to http://foo.bar.edu:3000/tripal.
If the page is not styled correctly, we exposed some environment variables that you can customize:

```
# In most situations, the following variables don't need to be set
# as they are autodetected. If needed, setting these variables will disable autodetection
VIRTUAL_HOST: foo.bar.edu # Guessed from HTTP_X_FORWARDED_HOST if behind a proxy, or from hostname
BASE_URL_PROTO: "http" # Guessed from apache REQUEST_SCHEME variable
BASE_URL: "http://foo.bar.edu:3000/tripal" # Guessed from VIRTUAL_HOST and BASE_URL_PROTO
```

### Customizing the Image

To build a derivative image from this, it should be as simple as writing a Dockerfile which builds off of this image.

```Dockerfile
FROM erasche/tripal
```

If you wish to load additional drupal modules, we have exposed the environment variables `TRIPAL_DOWNLOAD_MODULES` and `TRIPAL_ENABLE_MODULES` to allow for this. Note that `TRIPAL_ENABLE_MODULES` already has a large number of non-core modules enabled. You can change this list according to your preferences. Modules that are in `TRIPAL_ENABLE_MODULES` but not in `TRIPAL_DOWNLOAD_MODULES` will be automatically downloaded in their latest stable version.

```
ENV TRIPAL_DOWNLOAD_MODULES tripal_analysis_blast-7.x-2.x-dev
ENV TRIPAL_ENABLE_MODULES="tripal_genetic tripal_natural_diversity tripal_phenotype tripal_project tripal_pub tripal_stock tripal_analysis_blast"
```

If you need to install a module that is not hosted on http://www.drupal.org, you can fill the `TRIPAL_GIT_CLONE_MODULES` environment variable with a list of git repositories that will be cloned in the module directory.

```
ENV TRIPAL_GIT_CLONE_MODULES="https://github.com/abretaud/tripal_rest_api.git https://github.com/tripal/tripal_analysis_expression.git"
```

### Tripal usage

The container is configured (with cron) to launch Tripal jobs in queue every 2 minutes.
The log of these jobs is available in the /var/log/tripal_jobs.log log file, which is emptied regularly.

## Credentials

Username         | Password
---------------- | ---------
admin            | changeme

## Contributing

Please submit all issues and pull requests to the [erasche/docker-tripal](http://github.com/erasche/docker-tripal) repository.

## Support

If you have any problem or suggestion please open an issue [here](https://github.com/erasche/docker-tripal/issues).
