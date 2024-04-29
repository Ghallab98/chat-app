# chat-app

to run
should set xpack.security.enabled=false in elasticsearch.yml
rails db:migrate:reset
rails db:seed
bundle exec rake searchkick:reindex CLASS=Message
