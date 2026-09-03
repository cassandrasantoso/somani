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

    hit  = fetch_hit
    tags = hit ? Array(hit["jlpt"]) : []

    # JMdict's "uk" marker as jisho renders it. A factual usage note, independent
    # of any JLPT reconstruction: the word is normally written in kana, so the
    # kanji spelling is harder than the word itself (為さる vs なさる).
    kana = hit ? Array(hit["senses"]).any? { |s| Array(s["tags"]).include?("Usually written using kana alone") } : false

    easiest = tags.filter_map { |t| t[TAG, 1]&.to_i }.max

    if easiest.blank?
      @entry.update!(verified_at: Time.current, kana_preferred: kana)
      return Result.new(status: :no_data, tags: tags)
    end

    corrected = "N#{easiest}"
    was       = @entry.level

    if corrected == was
      @entry.update!(verified_at: Time.current, level_source: "jisho", kana_preferred: kana)
      Result.new(status: :unchanged, from: was, to: was, tags: tags)
    else
      @entry.update!(
        original_level: @entry.original_level || was,
        level: corrected,
        level_source: "jisho",
        verified_at: Time.current,
        kana_preferred: kana
      )
      Result.new(status: :corrected, from: was, to: corrected, tags: tags)
    end
  end

  private

  def fetch_hit
    uri = URI("#{ENDPOINT}?keyword=#{URI.encode_www_form_component(@entry.content)}")
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = USER_AGENT

    body = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(req)
    end.body

    data = JSON.parse(body)["data"] || []

    # Exact-form match, NOT data[0] — querying 宜しく returns four entries and the
    # first is not the right one.
    data.find do |d|
      Array(d["japanese"]).any? { |j| j["word"] == @entry.content || j["reading"] == @entry.content }
    end
  end
end
