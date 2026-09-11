Rack::Attack.cache.store = Rails.cache

class Rack::Attack
  throttle("reqs/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Each chat turn fans out to three Gemini calls plus TTS, so the chat
  # gets a tight per-minute ceiling.
  throttle("chat/ip", limit: 30, period: 1.minute) do |req|
    req.post? && req.path.end_with?("/messages") ? req.ip : nil
  end

  # Every upload triggers an extraction and a summary, and every extract
  # retry re-runs extraction — all of it against paid APIs.
  throttle("uploads/ip", limit: 10, period: 1.hour) do |req|
    req.post? && (req.path == "/uploads" || req.path.end_with?("/sample") || req.path.end_with?("/extract")) ? req.ip : nil
  end

  self.throttled_responder = lambda do |request|
    retry_after = request.env["rack.attack.match_data"][:period].to_i

    [429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
     ['{ "error": "Rate limit exceeded. Try again soon." }']]
  end
end
