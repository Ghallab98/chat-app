class Message < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  searchkick callbacks: :async, text_middle: [:body]
  # after_commit :index_message, on: [:create, :update]
  # after_destroy :remove_from_index
  belongs_to :chat

  validates :number, presence: true, uniqueness: { scope: :chat_id }
  validates :body, presence: true

  after_initialize :set_default_number, if: :new_record?

  # def index_message
  #   Message.import
  # end

  # def remove_from_index
  #   Message.delete(self.id)
  # end

  private

  def set_default_number
    return if number.present?
    
    last_message = chat.messages.order(:number).last
    self.number = last_message.present? ? last_message.number + 1 : 1
  end
end
