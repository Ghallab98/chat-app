class MessageCreationWorker
  include Sidekiq::Worker

  def perform
    redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])
    message_data = fetch_messages_from_redis(redis)

    return if message_data.empty?

    token_to_id_mapping = fetch_applications(message_data)
    application_chat_number_to_id_mapping = fetch_chats(token_to_id_mapping.values)

    messages = build_messages(message_data, token_to_id_mapping, application_chat_number_to_id_mapping)

    import_messages(messages)
    remove_messages_from_redis(redis)
  end

  private

  def fetch_messages_from_redis(redis)
    redis.lrange('messages_creation', 0, 9).reverse
  end

  def remove_messages_from_redis(redis)
    redis.ltrim('messages_creation', 10, -1)
  end

  def fetch_applications(message_data)
    application_tokens = message_data.map { |data| JSON.parse(data)['application_token'] }
    applications = Application.where(token: application_tokens)
    applications.index_by(&:token)
  end

  def fetch_chats(application_ids)
    chats = Chat.where(application_id: application_ids)
    chats.index_by { |chat| [chat.application_id, chat.number] }
  end

  def build_messages(message_data, token_to_id_mapping, app_chat_number_to_id_mapping)
    message_data.map do |data|
      attributes = JSON.parse(data)
      Message.new({ 'body' => attributes['body'], 'chat_id' => app_chat_number_to_id_mapping[[token_to_id_mapping[attributes['application_token']].id, attributes['chat_number']]].id, 'number' => attributes['number']})
    end
  end

  def import_messages(messages)
    begin
      Message.import(messages, validate: true)
    rescue => e
      logger.error "Failed to import messages: #{e.message}"
      raise
    end
  end
end