class ChatCountWorker
  include Sidekiq::Worker

  def perform
    redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])
    applications = redis.hgetall('applications')

    # Fetch all applications and create a mapping from application_token to {id, name}
    token_to_id_name_mapping = Application.pluck(:token, :id, :name).each_with_object({}) do |(token, id, name), hash|
      hash[token] = { id: id, name: name }
    end

    records = applications.map do |application_token, chats_count|
      {
        id: token_to_id_name_mapping[application_token][:id],
        token: application_token,
        name: token_to_id_name_mapping[application_token][:name],
        chats_count: chats_count.to_i
      }
    end

    begin
      columns = [:id, :token, :name, :chats_count]
      values = records.map { |record| [record[:id], record[:token], record[:name], record[:chats_count]] }

      Application.bulk_import columns, values, on_duplicate_key_update: [:chats_count]
    rescue => e
      logger.error "Failed to update chats_count: #{e.message}"
    end
  end
end