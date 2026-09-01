# A reply that doesn't engage with what was asked isn't genuine practice,
# whatever words it happens to contain. Runs independently of
# IndexWordCorrections which means that a disconnected reply may have no corrections
# at all (nothing wrong with the word itself, just nothing it was said in response to),
# so it needs its own path to revoke_credit's job.
class RevokeForDisconnection
  def self.call(feedback) = new(feedback).call

  def initialize(feedback)
    @feedback  = feedback
    @message   = feedback.message
    @adventure = @message.adventure
  end

  def call
    return unless @feedback.disconnected?

    changed = @message.word_usages.credited
                      .update_all(status: "revoked", updated_at: Time.current)
    return if changed.zero?

    @adventure.re_evaluate_goal!
    @adventure.broadcast_tracker
    @adventure.broadcast_goal_banner
  end
end
