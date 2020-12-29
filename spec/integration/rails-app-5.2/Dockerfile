FROM rails:5.2

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

RUN bundle install

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0", "-e", "production"]
