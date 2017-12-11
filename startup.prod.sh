#!/bin/bash

source .env
whenever --update-crontab
cron
bundle exec sidekiq &
rails server -b 0.0.0.0
