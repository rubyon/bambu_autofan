FROM ruby:3.3

WORKDIR /usr/src/app

COPY Gemfile ./
RUN bundle install

COPY . .

RUN chmod +x bambu.rb

CMD ["./bambu.rb"]
