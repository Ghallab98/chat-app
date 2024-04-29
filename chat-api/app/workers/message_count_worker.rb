class MessageCountWorker
  include Sidekiq::Worker

  def perform
    redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])
    chats = redis.hgetall('chats')

    # Fetch all apps and create a mapping from application_token to application_id
    token_to_id_mapping = Application.pluck(:token, :id).to_h

    records = chats.map do |key, messages_count|
      application_token, chat_number = key.split(',')
      {
        application_id: token_to_id_mapping[application_token],
        number: chat_number.to_i,
        messages_count: messages_count.to_i
      }
    end

    begin
      columns = [:application_id, :number, :messages_count]
      values = records.map { |record| [record[:application_id], record[:number], record[:messages_count]] }

      result = Chat.bulk_import columns, values, on_duplicate_key_update: [:messages_count]
    rescue => e
      logger.error "Failed to update messages_count: #{e.message}"
    end
  end
end