class ChatCreationWorker
  include Sidekiq::Worker

  def perform
    redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])
    chat_data = fetch_chats_from_redis(redis)

    return if chat_data.empty?

    token_to_id_mapping = fetch_applications(chat_data)

    chats = build_chats(chat_data, token_to_id_mapping)

    import_chats(chats)
    remove_chats_from_redis(redis)
  end

  private

  def fetch_chats_from_redis(redis)
    redis.lrange('chats_creation', 0, 9).reverse
  end

  def remove_chats_from_redis(redis)
    redis.ltrim('chats_creation', 10, -1)
  end

  def fetch_applications(chat_data)
    application_tokens = chat_data.map { |data| JSON.parse(data)['application_token'] }
    applications = Application.where(token: application_tokens)
    applications.index_by(&:token)
  end

  def build_chats(chat_data, token_to_id_mapping)
    chat_data.map do |data|
      attributes = JSON.parse(data)
      Chat.new({ 'application_id' => token_to_id_mapping[attributes['application_token']].id, 'number' => attributes['number']})
    end
  end

  def import_chats(chats)
    begin
      Chat.import(chats, validate: true)
    rescue => e
      logger.error "Failed to import chats: #{e.message}"
      raise
    end
  end
end