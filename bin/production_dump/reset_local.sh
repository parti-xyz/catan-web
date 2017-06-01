#!/bin/bash
set -e

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit
fi

file_name=$1
branch_namne=`git rev-parse --abbrev-ref HEAD`

. bin/production_dump/parse_yaml.sh

eval $(parse_yaml ./local_env.yml "config_")

if [ ! -z "$config_development_database_password" ]
then
  pass="-p${config_development_database_password}"
fi


ey scp HOST:/mnt/tmp/$file_name . -e omurice
mysql -u$config_development_database_username $pass -e "DROP DATABASE catan_development_${branch_namne}; CREATE DATABASE catan_development_${branch_namne} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
gunzip -c $file_name | mysql -uroot $pass catan_development_$branch_namne
rm -rf $file_name
