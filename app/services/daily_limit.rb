# Per-user cost protection, complementary to the per-IP Rack::Attack limits:
# a signed-in abuser rotating IPs still hits these. Limits are env-configurable
# so they can tighten without a deploy when real usage data exists.
class DailyLimit
  DEFAULT_MESSAGE_LIMIT = 100
  DEFAULT_UPLOAD_LIMIT = 10

  def self.messages_today(user)
    Message.joins(adventure: :upload)
           .where(uploads: { user_id: user.id })
           .where(created_at: Time.current.beginning_of_day..)
           .count
  end

  def self.uploads_today(user)
    user.uploads.where(created_at: Time.current.beginning_of_day..).count
  end

  def self.message_limit
    ENV.fetch("DAILY_MESSAGE_LIMIT", DEFAULT_MESSAGE_LIMIT).to_i
  end

  def self.upload_limit
    ENV.fetch("DAILY_UPLOAD_LIMIT", DEFAULT_UPLOAD_LIMIT).to_i
  end

  def self.message_exceeded?(user)
    messages_today(user) >= message_limit
  end

  def self.upload_exceeded?(user)
    uploads_today(user) >= upload_limit
  end
end
