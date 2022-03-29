#!/bin/bash
set -e

function run_scripts () {
	SCRIPTS_DIR="/scripts/$1.d"
	SCRIPT_FILES_PATTERN="^${SCRIPTS_DIR}/[0-9][0-9][a-zA-Z0-9_-]+$"
	SCRIPTS=$(find "$SCRIPTS_DIR" -type f -uid 0 -executable -regex "$SCRIPT_FILES_PATTERN" | sort)
	if [ -n "$SCRIPTS" ] ; then
		echo "=>> $1-scripts:"
	    for script in $SCRIPTS ; do
	        echo "=> $script"
			. "$script"
	    done
	fi
}

### auto-configure database from environment-variables

DB_DRIVER=pgsql
: ${DB_HOST:='postgres'}
: ${DB_PORT:='5432'}
: ${DB_NAME:='postgres'}
: ${DB_USER:='postgres'}
: ${DB_PASS:='postgres'}

: ${ADMIN_USER:='admin'}  # DO NOT export!
: ${ADMIN_PASSWORD:='changeme'}  # DO NOT export!

DRUPAL_HASH_SALT=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1`

PGHOST=${DB_HOST};
PGPORT=${DB_PORT};
PGDATABASE=${DB_NAME};
PGUSER=${DB_USER};
PGPASSWORD=${DB_PASS};
export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
export DB_DRIVER DB_HOST DB_PORT DB_NAME DB_USER DB_PASS DRUPAL_HASH_SALT
echo -e "# Drupals's database configuration, parsed in /var/www/sites/default/settings.php\n
export DB_DRIVER=${DB_DRIVER} DB_HOST=${DB_HOST} DB_PORT=${DB_PORT} DB_NAME=${DB_NAME} DB_USER=${DB_USER} DB_PASS=${DB_PASS} DRUPAL_HASH_SALT=${DRUPAL_HASH_SALT}" >> /etc/profile
echo -e "# Drupals's database configuration, parsed in /var/www/sites/default/settings.php\n
export DB_DRIVER=${DB_DRIVER} DB_HOST=${DB_HOST} DB_PORT=${DB_PORT} DB_NAME=${DB_NAME} DB_USER=${DB_USER} DB_PASS=${DB_PASS} DRUPAL_HASH_SALT=${DRUPAL_HASH_SALT}" >> /etc/bash.bashrc


###  connect to database

echo
echo "=> Trying to connect to a database using:"
echo "      Database Driver:   $DB_DRIVER"
echo "      Database Host:     $DB_HOST"
echo "      Database Port:     $DB_PORT"
echo "      Database Username: $DB_USER"
echo "      Database Password: $DB_PASS"
echo "      Database Name:     $DB_NAME"
echo

for ((i=0;i<20;i++))
do
    DB_CONNECTABLE=$(PGPASSWORD=$DB_PASS psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -l >/dev/null 2>&1; echo "$?")
	if [[ $DB_CONNECTABLE -eq 0 ]]; then
		break
	fi
    sleep 3
done

if ! [[ $DB_CONNECTABLE -eq 0 ]]; then
	echo "Cannot connect to database"
    exit "${DB_CONNECTABLE}"
fi


### Initial setup if database doesn't exist
if [ "$(PGPASSWORD=$DB_PASS psql -U $DB_USER -h $DB_HOST -p $DB_PORT postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" )" != '1' ]
then
    echo "Database $DB_NAME does not exist, creating it"
    echo "CREATE DATABASE $DB_NAME;" | psql -U $DB_USER -h $DB_HOST -p $DB_PORT postgres;
fi

# Add possibly missing files/dirs if sites dir is empty (files needed by drush pm-list)
if [ ! -e /var/www/html/sites/default ]; then
    mkdir -p /var/www/html/sites/default/
fi

if [ ! -e /var/www/html/sites/default/settings.php ]; then
    cp /etc/tripal/settings.php /var/www/html/sites/default/settings.php
fi

# Check if tables are there and that drush works
DB_LOADED=$(PGPASSWORD=$DB_PASS psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'organism');")
DRUSH_OK=`export ENABLE_MEMCACHE=0 && drush pm-list > /dev/null 2>&1; echo "$?"`
if [[ $DRUSH_OK != "0" && $DB_LOADED != "t" ]]
then
	run_scripts setup
	echo "=> Done installing site!"
	if [ $EXTRA_SETUP_SCRIPT ]; then
		echo "=> WARNING: The usage of EXTRA_SETUP_SCRIPT is deprecated. Put your script into /scripts/post-setup.d/"
		. $EXTRA_SETUP_SCRIPT
		echo "=> Successfully ran extra setup script ${EXTRA_SETUP_SCRIPT}."
	fi
elif [[ $DRUSH_OK == "0" && $DB_LOADED != "t" ]]
then
	echo "=> Error: 'drush pm-list' ok but could not find chado tables. Something is wrong in the install. Exiting."
    exit 1
elif [[ $DRUSH_OK != "0" && $DB_LOADED == "t" ]]
then
	echo "=> Error: 'drush pm-list' fails but the database is not empty. Trying to upgrade db, just in case."
	export ENABLE_MEMCACHE=0 && drush updb -y
	echo "drush updb finished, retrying pm-list"

	DRUSH_OK=`export ENABLE_MEMCACHE=0 && drush pm-list > /dev/null 2>&1; echo "$?"`

	if [[ $DRUSH_OK != "0" ]]
	then
			echo "=> Error: 'drush pm-list' fails again but the database is not empty. Something is wrong in the install. Exiting."
			export ENABLE_MEMCACHE=0 && drush pm-list
			exit $?
	fi
else
	echo "=> Skipped setup - database ${DB_NAME} already ready."
fi


###

run_scripts pre-launch

unset ADMIN_USER
unset ADMIN_PASSWORD

exec apache2-foreground

exit 1
