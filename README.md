# Tripal Docker Image

[![Docker Automated build](https://img.shields.io/docker/automated/erasche/tripal.svg?style=flat-square)](https://hub.docker.com/r/erasche/tripal/)
[![DOI](https://zenodo.org/badge/10899/erasche/docker-tripal.svg)](https://zenodo.org/badge/latestdoi/10899/erasche/docker-tripal)

![Tripal Logo](http://tripal.info/sites/default/files/TripalLogo_dark.png)

This image contains a ready-to-go installation of Tripal v2.x.

## Using the Container

We highly recommend using a `docker-compose.yml` to run your containers.
The following example will run 3 docker containers:

 - `tripal`: contains the Tripal code served by an Apache server
 - `db`: a postgresql server hosting the Chado database used by Tripal
 - `elasticsearch`: an elasticsearch server used by Tripal to index data when the tripal_elasticsearch module is enabled.

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
      TRIPAL_DOWNLOAD_MODULES: "tripal_analysis_blast-7.x-2.x-dev"
      TRIPAL_GIT_CLONE_MODULES: "https://github.com/tripal/tripal_analysis_expression.git"
      TRIPAL_ADDITIONAL_MODULES: "tripal_analysis_blast tripal_analysis_expression tripal_analysis_interpro"
    ports:
      - "3000:80"
  db:
    image: erasche/chado
    environment:
      - POSTGRES_PASSWORD=postgres
        # The default chado image would try to install the schema on first run,
        # we just want the GMOD tools to be available.
      - INSTALL_CHADO_SCHEMA=0
      - INSTALL_YEAST_DATA=0
      - PGDATA=/var/lib/postgresql/data/
    volumes:
      - /var/lib/postgresql/data/

  elasticsearch:
    image: elasticsearch
```

## Configuring the Container

By default, tripal should display properly by going to http://foo.bar.edu:3000/tripal.
If the page is not styled correctly, we exposed some environment variables that you can customize:

```
# In most situations, the following variables don't need to be set
# as they are autodetected. If needed, setting these variables will disable autodetection
VIRTUAL_HOST: foo.bar.edu # Guessed from HTTP_X_FORWARDED_HOST if behind a proxy, or from hostname
BASE_URL_PROTO: "http" # Guessed from apache REQUEST_SCHEME variable
BASE_URL_PATH: "/tripal" # Default is /tripal
BASE_URL: "http://foo.bar.edu:3000/tripal" # Guessed from VIRTUAL_HOST, BASE_URL_PROTO and BASE_URL_PATH
```

You can change the website name and default theme using the following variables:

```
SITE_NAME: "My Tripal instance"
THEME: "bartik"
```

You can also install alternate drupal themes with the THEME_GIT_CLONE variable:

```
THEME_GIT_CLONE: "https://github.com/example/foobar.git"
THEME: "foobar"
```

By default some caching is done for better performances. You can disable it with the following variables:

```
ENABLE_OP_CACHE: 0 # To disable the PHP opcache
ENABLE_DRUPAL_CACHE: 0 # To disable Drupal built-in cache
ENABLE_MEMCACHE: 0 # To disable caching using memcache (requires ENABLE_DRUPAL_CACHE=1)
```

If ENABLE_DRUPAL_CACHE is enabled but ENABLE_MEMCACHE is not, Drupal will cache data into database.
If both ENABLE_DRUPAL_CACHE and ENABLE_MEMCACHE are enabled, Drupal will cache data using memcache.

## Customizing the Image

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

If you want to get a specific git revision, you can use this syntax:

```
ENV TRIPAL_GIT_CLONE_MODULES="https://github.com/abretaud/tripal_rest_api.git[@8fe9b4d48c2ca4310658ab0fb48f6af2bf5b3bcd]"
```

## Tripal jobs

When loading data into Tripal, jobs or indexing tasks will be created inside the container.

If you are using [Tripaille](https://github.com/abretaud/python-tripal) to load data, you have nothing specific to do, jobs will be launched automatically for you.

If you don't use Tripaille, you will need to manually launch Tripal jobs or indexing tasks, as described in the Tripal documentation:

```
# Launch all jobs in queue
docker-compose exec web "drush trp-run-jobs --username=admin"

# Launch indexing tasks in all queues
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_0"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_1"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_2"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_3"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_4"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_5"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_6"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_7"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_8"
docker-compose exec web "export BASE_URL=http://localhost/ && /usr/local/bin/drush cron-run queue_elasticsearch_queue_9"
```

The container can also be configured to launch Tripal jobs automatically every 2 minutes using cron:

```
ENABLE_CRON_JOBS=1
```

The downside of this option is that cron will coninue to launch processes every 2 minutes, even when no jobs are scheduled, leading to a little more cpu usage every 2 minutes.
The log of these jobs will be available in the /var/log/tripal_jobs.log and /var/log/tripal_cron.log log files.

## Data backup

To ease the backup of a tripal instance, you can mount several docker volumes by modifying the docker-compose.yml file:

```yaml
version: "2"
services:
  tripal:
    image: erasche/tripal:latest
    [...]
    volumes:
      - ./your/backed/up/dir/tripal_sites:/var/www/html/sites
      - ./your/backed/up/dir/tripal_private:/var/www/private
      [...]
  db:
    image: erasche/chado
    [...]
    volumes:
      - ./your/backed/up/dir/tripal_db:/var/lib/postgresql/data/

  elasticsearch:
    image: elasticsearch
    volumes:
      - ./your/backed/up/dir/tripal_index/:/usr/share/elasticsearch/data
```

You can then launch regular backups of ./your/backed/up/dir/

## Elasticsearch configuration

You may encounter the following error when launching the elasticsearch container:

```
initial heap size [268435456] not equal to maximum heap size [1073741824]; this can cause resize pauses and prevents mlockall from locking the entire heap
```

As explained [here](https://github.com/docker-library/elasticsearch/issues/98#issuecomment-218071315), you will need to increase the `vm.max_map_count` setting on the host where the docker is running by launching:

```
sudo sysctl -w vm.max_map_count=262144
```

This setting will get reset to the default value when restarting the host. To make it permanent, add this line to `/etc/sysctl.d/99-sysctl.conf`:

```
vm.max_map_count=262144
```

## Credentials

An admin account is autocreated with the following credentials:

Username         | Password
---------------- | ---------
admin            | changeme

To customize this, the following environment variables are available:

```
ENV ADMIN_USER admin
ENV ADMIN_PASSWORD changeme
```

## Contributing

Please submit all issues and pull requests to the [erasche/docker-tripal](http://github.com/erasche/docker-tripal) repository.

## Support

If you have any problem or suggestion please open an issue [here](https://github.com/erasche/docker-tripal/issues).
