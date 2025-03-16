#!/bin/bash

#create database
rails db:create
rails db:migrate

#start rails server
rm -f tmp/pids/server.pid
exec "$@"