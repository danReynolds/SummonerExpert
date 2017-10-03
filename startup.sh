#!/bin/bash

whenever --update-crontab
cron
rails server -b 0.0.0.0
