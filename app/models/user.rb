class User < ActiveRecord::Base

  has_secure_password

  has_many :microposts, dependent: :destroy
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :reverse_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: "followed"
  has_many :followers, through: :reverse_relationships, source: "follower"

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name, presence: true, length: {maximum: 50}
  validates :email,
    presence: true,
    format: {with: VALID_EMAIL_REGEX},
    uniqueness: {case_sensitive: false}
  validates :password, presence: true, length: {minimum: 6}
  validates :password_confirmation, presence: true

  before_save { email.downcase! }
  before_create :create_remember_token
  after_validation { self.errors.messages.delete(:password_digest) }

  def self.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def self.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(followed_user)
    relationships.find_by_followed_id followed_user.id
  end

  def follow!(followed_user)
    relationships.create!(followed_id: followed_user.id)
  end

  def unfollow!(followed_user)
    relationships.find_by_followed_id(followed_user.id).destroy
  end

  def followed_user_ids
    followed_users.map(&:id)
  end

  private

  def create_remember_token
    self.remember_token = User.encrypt(User.new_remember_token)
  end

end
