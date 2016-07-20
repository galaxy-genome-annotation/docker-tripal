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
DB_HOST=postgres
: ${DB_PORT:='5432'}
: ${DB_NAME:='postgres'}
: ${DB_USER:='postgres'}
: ${DB_PASS:='postgres'}

: ${ADMIN_USER:='admin'}  # DO NOT export!
: ${ADMIN_PASSWORD:='changeme'}  # DO NOT export!

export DB_DRIVER DB_HOST DB_PORT DB_NAME DB_USER DB_PASS
echo -e "# Drupals's database configuration, parsed in /var/www/sites/default/settings.php\n
export DB_DRIVER=${DB_DRIVER} DB_HOST=${DB_HOST} DB_PORT=${DB_PORT} DB_NAME=${DB_NAME} DB_USER=${DB_USER} DB_PASS=${DB_PASS}" >> /etc/bash.bashrc


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

if ! drush pm-list > /dev/null 2>&1; then
	run_scripts setup
	echo "=> Done installing site!"
	if [ $EXTRA_SETUP_SCRIPT ]; then
		echo "=> WARNING: The usage of EXTRA_SETUP_SCRIPT is deprectated. Put your script into /scripts/post-setup.d/"
		. $EXTRA_SETUP_SCRIPT
		echo "=> Successfully ran extra setup script ${EXTRA_SETUP_SCRIPT}."
	fi
	else
	echo "=> Skipped setup - database ${DB_NAME} already exists."
fi


###

run_scripts pre-launch

unset ADMIN_USER
unset ADMIN_PASSWORD

exec apache2-foreground

exit 1
