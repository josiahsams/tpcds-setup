#!/bin/bash

mysql -u hive -phivepassword -e "use metastore_db; select NAME as 'DB_Name' from DBS where NAME != 'default';"
