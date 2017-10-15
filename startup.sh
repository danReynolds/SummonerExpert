#!/bin/bash

touch .env
source .env
if [ "$RAILS_ENV" = "development" ]
then
  # Turn on cache in dev environment
  rails dev:cache
fi
whenever --update-crontab
cron
rails server -b 0.0.0.0
