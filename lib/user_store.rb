require "securerandom"

class UserStore
  include Mongoid::Document
  include Mongoid::Timestamps

  field :secret, type: String
  field :uid,    type: String
  field :name,   type: String
  field :email,  type: String
  field :avatar, type: String

  has_many :likes

  before_save do
    self.generate_secret! if !self.secret
  end

  def generate_secret!
    self.secret = SecureRandom.hex(16)
  end
end
