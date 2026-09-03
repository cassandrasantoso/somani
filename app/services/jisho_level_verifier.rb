require "net/http"
require "uri"

class JishoLevelVerifier
  TAG      = /\Ajlpt-n([1-5])\z/
  ENDPOINT = "https://jisho.org/api/v1/search/words".freeze
  USER_AGENT = "Somani/1.0 (JLPT level verification; +https://github.com/cassandrasantoso/somani)".freeze

  Result = Struct.new(:status, :from, :to, :tags, keyword_init: true)

  def self.call(entry) = new(entry).call

  def initialize(entry)
    @entry = entry
  end

  # status is :skipped, :no_data, :unchanged, or :corrected
  def call
    return Result.new(status: :skipped) if @entry.verified_at.present?

    tags    = fetch_tags
    easiest = tags.filter_map { |t| t[TAG, 1]&.to_i }.max

    if easiest.blank?
      # Mark it seen so a re-run doesn't keep re-querying words jisho has no
      # JLPT data for. Level and level_source are left exactly as they were.
      @entry.update!(verified_at: Time.current)
      return Result.new(status: :no_data, tags: tags)
    end

    # jisho returns every level tag on the JMdict entry, which groups surface
    # variants. The easiest belongs to the common form — the same "easiest wins"
    # rule jlpt:import already applies across files. Confirmed correct by
    # jlpt:probe_variants: 6/10 multi-tag entries had kept the hardest.
    corrected = "N#{easiest}"
    was       = @entry.level

    if corrected == was
      @entry.update!(verified_at: Time.current, level_source: "jisho")
      Result.new(status: :unchanged, from: was, to: was, tags: tags)
    else
      @entry.update!(
        original_level: @entry.original_level || was,
        level: corrected,
        level_source: "jisho",
        verified_at: Time.current
      )
      Result.new(status: :corrected, from: was, to: corrected, tags: tags)
    end
  end

  private

  def fetch_tags
    uri = URI("#{ENDPOINT}?keyword=#{URI.encode_www_form_component(@entry.content)}")
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = USER_AGENT

    body = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(req)
    end.body

    data = JSON.parse(body)["data"] || []

    # Exact-form match, NOT data[0] — querying 宜しく returns four entries and the
    # first is not the right one.
    hit = data.find do |d|
      Array(d["japanese"]).any? { |j| j["word"] == @entry.content || j["reading"] == @entry.content }
    end

    hit ? Array(hit["jlpt"]) : []
  end
end
