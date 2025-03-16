#!/bin/bash

#create database
rails db:create RAILS_ENV=development
rails db:migrate RAILS_ENV=development

# Create database for test
rails db:create RAILS_ENV=test
rails db:migrate RAILS_ENV=test

#start rails server
rm -f tmp/pids/server.pid
rails server -b 0.0.0.0
# tail -f /dev/null
