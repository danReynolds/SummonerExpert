# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

env 'MAILTO', 'me@danreynolds.ca'
env 'REDIS_PASSWORD', ENV['REDIS_PASSWORD']

set :environment, "production"
set :output, { error: '/app/scheduler-error.log', standard: '/app/scheduler.log' }

ENV.each { |k, v| env(k, v) }

every 1.day, at: "03:30 am" do
  rake "champion_gg:all"
  rake "riot:all"
  command "echo Champion.gg $(ENV['REDIS_PASSWORD'])"
end
