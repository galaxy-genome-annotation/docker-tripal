# Tripal Docker Image

![Tripal Logo](http://tripal.info/sites/default/files/TripalLogo_dark.png)

This image contains a ready-to-go installation of Tripal v2.0.

## Using the Container

I highly recommend using a `docker-compose.yml` to run your containers.

```yaml
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
    DB_NAME: postgres
  ports:
    - "3000:80"

db:
  image: postgres:9.4
  environment:
    - POSTGRES_PASSWORD=password
  volumes:
    - /var/lib/postgresql/data
```

## Notes

It should be linked to a postgres container, instead of my chado
container. This is for a couple of reasons, namely my container won't
behave properly if you mount a volume and that's bad. Additionally, chado
is installed into the public schema in those containers (I mean, that
makes sense, right?), however Tripal expects Chado in a `chado` schema. My
[chado schema builder](https://github.com/erasche/docker-recipes/blob/master/compile-chado-schema/chado/default/build.yml#L56)
now accounts for that and generates multiple images.

## Contributing

Please submit all issues and pull requests to the [erasche/docker-tripal](http://github.com/erasche/docker-tripal) repository!

## Support

If you have any problem or suggestion please open an issue [here](https://github.com/erasche/docker-tripal/issues).
