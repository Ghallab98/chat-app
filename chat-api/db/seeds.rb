# # This file should ensure the existence of records required to run the application in every environment (production,
# # development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# # The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
# #
# # Example:
# #
# #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
# #     MovieGenre.find_or_create_by!(name: genre_name)
# #   end
# require 'redis'

# # Establish a connection to Redis
# redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])

# # Create two apps
# application1 = Application.create!(name: "Application1")
# application2 = Application.create!(name: "Application2")

# # Create chats for Application 1
# 2.times do |chat_index|
#   chat = application1.chats.build(number: chat_index + 1)
#   chat.save!

#   # Increment chats_count in Redis
#   redis.hincrby("applications", application1.token, 1)

#   # Create messages for each chat
#   rand(3..5).times do |message_index|
#     chat.messages.create!(body: Faker::Movie.title)
#     # Increment messages_count in Redis
#     redis.hincrby("chats", "#{application1.token},#{chat.number}", 1)
#   end
# end

# # Create chats for App 2
# 3.times do |index|
#   chat = application2.chats.build(number: index + 1)
#   chat.save!

#   # Increment chats_count in Redis
#   redis.hincrby("applications", application2.token, 1)

#   # Create messages for each chat
#   rand(3..5).times do |message_index|
#     chat.messages.create!(body: Faker::Movie.title)
#     # Increment messages_count in Redis
#     redis.hincrby("chats", "#{application2.token},#{chat.number}", 1)
#   end
# end