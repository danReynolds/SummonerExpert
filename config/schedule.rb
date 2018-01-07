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

set :environment, "production"
set :output, { error: '/app/scheduler-error.log', standard: '/app/scheduler.log' }

ENV.each { |k, v| env(k, v) }

every 1.day, at: "07:40 am" do
  command "echo Starting Nightly Redis Update at $(date) >> /app/scheduler.log"
  rake "champion_gg:all"
  rake "riot:daily"
end

every 1.day at: "9:30 am" do
  rake "riot:store_matches_fix"
end

every 1.hour do
  rake "riot:hourly"
end
