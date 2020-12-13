#!bin/sh
psql -U postgres -d $POSTGRES_DB -f source/db.sql > /dev/null
psql -U postgres -d $POSTGRES_DB -f source/populate.sql > /dev/null
psql -U postgres -d $POSTGRES_DB -f source/functions.sql > /dev/null
