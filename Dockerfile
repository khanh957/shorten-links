FROM ruby:3.2.2

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update -y && \
    apt-get install -y unzip xvfb \
    libqt5webkit5-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-tools gstreamer1.0-x \
    freetds-dev \
    libnss3 libxi6 libgconf-2-4 \
    build-essential \
    postgresql postgresql-contrib \
    redis

RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf && \
    echo "host all all 0.0.0.0/0 trust" >> /etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf

RUN service postgresql start && \
    su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\""

RUN sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf

WORKDIR /usr/src/app
COPY ./Gemfile ./Gemfile.lock ./
COPY .env .env
RUN gem install bundler -v 2.4.10
RUN bundle install

COPY . .

# Init script
COPY ./init.sh /
RUN apt-get update -y && \
  apt-get install -y dos2unix
RUN dos2unix /init.sh
RUN chmod +x /init.sh
ENTRYPOINT [ "/init.sh" ]

EXPOSE 3000
