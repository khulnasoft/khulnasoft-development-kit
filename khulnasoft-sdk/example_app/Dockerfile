FROM ruby:3.3.1

COPY . ./app
WORKDIR /app/example_app
RUN bundle install

ENTRYPOINT ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "5172"]
