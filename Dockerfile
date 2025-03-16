FROM ruby:3.2.2

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update -y && \
  apt-get install -y unzip xvfb \
  libqt5webkit5-dev \
  gstreamer1.0-plugins-base \
  gstreamer1.0-tools gstreamer1.0-x \
  freetds-dev \
  libnss3 libxi6 libgconf-2-4

WORKDIR /usr/src/app

# Install app
COPY ./Gemfile ./Gemfile.lock ./
RUN gem install bundler -v 2.4.10
RUN bundle install

# Init script
COPY ./init.sh /
COPY ./init-sidekiq.sh /
RUN apt-get update -y && \
  apt-get install -y dos2unix
RUN dos2unix /init.sh /init-sidekiq.sh
RUN chmod +x /init.sh /init-sidekiq.sh
ENTRYPOINT [ "/init.sh" ]

EXPOSE 3000
