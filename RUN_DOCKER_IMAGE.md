docker run -it -p 5432:5432 shorten_link

service postgresql start

service redis-server start

rails db:create db:migrate
rails server -b 0.0.0.0