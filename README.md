# Tripal Docker Image

[![DOI](https://zenodo.org/badge/10899/erasche/docker-tripal.svg)](https://zenodo.org/badge/latestdoi/10899/erasche/docker-tripal)

![Tripal Logo](http://tripal.info/sites/default/files/TripalLogo_dark.png)

This image contains a ready-to-go installation of Tripal v2.0.

## Using the Container

I highly recommend using a `docker-compose.yml` to run your containers.

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
      DB_NAME: 'tripal'
    ports:
      - "3000:80"
  db:
    image: erasche/chado:1.31-jenkins97
    environment:
      - POSTGRES_PASSWORD=postgres
        # The default chado image would try to install the schema on first run,
        # we just want the GMOD tools to be available.
      - INSTALL_CHADO_SCHEMA=0
      - INSTALL_YEAST_DATA=0
      - PGDATA=/var/lib/postgresql/data/
    volumes:
      - /var/lib/postgresql/data/
```

## Contributing

Please submit all issues and pull requests to the [erasche/docker-tripal](http://github.com/erasche/docker-tripal) repository!

## Support

If you have any problem or suggestion please open an issue [here](https://github.com/erasche/docker-tripal/issues).
