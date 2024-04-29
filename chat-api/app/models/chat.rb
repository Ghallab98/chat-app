class Chat < ActiveRecord::Base
  belongs_to :application
  has_many :messages, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :application_id }

  after_initialize :set_default_number, if: :new_record?

  private

  def set_default_number
    return if number.present?
    
    last_chat = application.chats.order(:number).last
    self.number = last_chat.present? ? last_chat.number + 1 : 1
  end
end
