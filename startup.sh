#!/bin/bash

source .env
whenever --update-crontab
cron
rails server -b 0.0.0.0
