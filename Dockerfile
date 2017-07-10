# Base Ruby layer
FROM ruby:2.3.3

# Add system libraries layer
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

# Set the working directory to /app
RUN mkdir /app
WORKDIR /app

# Install all needed gems
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN gem install bundler
RUN bundle install
RUN rails dev:cache

# Copy the current directory contents into the container at /app
ADD . /app

# Start server
CMD ["rails","server","-b", "0.0.0.0"]
