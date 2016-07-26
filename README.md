# Tripal Docker Image

[![DOI](https://zenodo.org/badge/10899/erasche/docker-tripal.svg)](https://zenodo.org/badge/latestdoi/10899/erasche/docker-tripal)

![Tripal Logo](http://tripal.info/sites/default/files/TripalLogo_dark.png)

This image contains a ready-to-go installation of Tripal v2.0.

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
      VIRTUAL_HOST: foo.bar.edu
      # If you run the image on a different port, then BASE_URL must be set
      # correctly. If you run on :80 it should be OK to remove BASE_URL
      BASE_URL: "http://foo.bar.edu:3000"
      BASE_URL_PROTO: "http://"
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

You will need to set a `BASE_URL` unfortunately, if drupal/tripal use this in finding the location of the CSS and other static files. The container will come up correctly and you will be able to access the page, but it will not be styled without this set correctly.

### Customizing the Image

To build a derivative image from this, it should be as simple as writing a Dockerfile which builds off of this image.

```Dockerfile
FROM erasche/tripal
```

If you wish to load additional drupal modules, we have exposed the environment variables `TRIPAL_DOWNLOAD_MODULES` and  to allow for this. Note that `TRIPAL_ADDITIONAL_MODULES` already has a large number of non-core modules enabled. You can change this list according to your preferences.

```
ENV TRIPAL_DOWNLOAD_MODULES tripal_analysis_blast-7.x-2.x-dev
ENV TRIPAL_ADDITIONAL_MODULES="tripal_genetic tripal_natural_diversity tripal_phenotype tripal_project tripal_pub tripal_stock tripal_analysis_blast"
```


## Contributing

Please submit all issues and pull requests to the [erasche/docker-tripal](http://github.com/erasche/docker-tripal) repository.

## Support

If you have any problem or suggestion please open an issue [here](https://github.com/erasche/docker-tripal/issues).
