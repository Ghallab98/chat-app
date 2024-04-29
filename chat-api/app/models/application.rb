class Application < ActiveRecord::Base
  before_validation :generate_token, on: :create

  has_many :chats, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true

  private
  def generate_token
    self.token ||= SecureRandom.hex(10)
  end
end
