# data_base_homework

## How to use with docker-compose

`docker-compose up` to start PostgreSQL server

`docker-compose down -v` to shut the server down and remove postgres_data volume

`docker-compose exec postgres source/init.sh` to create tables, populate them and create functions

`docker-compose exec postgres bash` to open bash terminal in postgres container

`5532` port is used on host machine (`5432` may be taken by your system PostgreSQL instance), so you can use it with system `psql` or `PgAdmin`.
