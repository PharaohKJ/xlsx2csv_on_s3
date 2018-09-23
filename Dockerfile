FROM ruby:2.5

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock main.rb ./
RUN bundle install

ENTRYPOINT ["ruby"]
CMD ["main.rb"]
