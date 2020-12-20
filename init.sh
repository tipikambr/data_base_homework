#!bin/sh
psql -U postgres -d $POSTGRES_DB -f source/db.sql > /dev/null

for f in source/functions/*.sql; do
	psql -U postgres -d $POSTGRES_DB -f $f > /dev/null;
done

psql -U postgres -d $POSTGRES_DB -f source/populate.sql > /dev/null
