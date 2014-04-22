class Like
  include Mongoid::Document
  include Mongoid::Timestamps

  field :scope, type: String
  field :key,   type: String

  validates :key, presence: true
  validates :key, format: {with: /[a-zA-Z0-9_]+/}

  belongs_to :user_store
end
