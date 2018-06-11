#!/bin/bash

rm -f tmp/pids/server.pid
bundle exec sidekiq &
rails server -b 0.0.0.0
