class GenerateUploadSceneJob < ApplicationJob
  queue_as :default

  retry_on Faraday::TooManyRequestsError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  VOICES = %w[ja-JP-NanamiNeural ja-JP-KeitaNeural ja-JP-AoiNeural].freeze
  DEDUP_DISTANCE = 0.4

  # Runs after the upload summary exists (chained from GenerateUploadSummaryJob).
  # Designs one new character + scene grounded in the upload's topic, so the
  # scene library grows with what learners actually read — instead of staying
  # frozen at the nine bundled seeds. Skips when an existing scene already
  # covers the topic, so re-runs and similar uploads don't pile up near-duplicates.
  def perform(upload)
    return if upload.summary.blank?

    entries = upload.matched_jlpt_entries
    return if entries.blank?

    summary_embedding = EmbeddingService.generate(upload.summary)
    return if summary_embedding.blank?

    nearest = Scene.where.not(embedding: nil)
                   .nearest_neighbors(:embedding, summary_embedding, distance: "cosine")
                   .first
    return if nearest && nearest.neighbor_distance < DEDUP_DISTANCE

    data = GeminiClient.generate_json(scene_prompt(upload, entries))
    return unless valid_payload?(data)

    character = Character.create!(
      name: data["character_name"].to_s.strip,
      persona: data["persona"].to_s.strip,
      voice: VOICES[upload.id % VOICES.size]
    )
    character.scenes.create!(
      setting: data["setting"].to_s.strip,
      description: data["description"].to_s.strip,
      level: level_for(entries),
      source: :generated
    )
  rescue Faraday::TooManyRequestsError
    raise
  rescue StandardError => e
    Rails.logger.warn("GenerateUploadSceneJob upload=#{upload.id}: #{e.class}: #{e.message}")
  end

  private

  def valid_payload?(data)
    data.is_a?(Hash) &&
      data["character_name"].present? &&
      data["persona"].present? &&
      data["setting"].present? &&
      data["description"].present?
  end

  # The level the conversation should aim at: the most common level among the
  # words the upload actually matched — the pool the learner will pick from.
  def level_for(entries)
    levels = entries.filter_map(&:level).tally
    return Scene::DEFAULT_LEVEL if levels.empty?

    levels.max_by { |_level, count| count }.first
  end

  def scene_prompt(upload, entries)
    words = entries.first(30).map(&:content).uniq.join("、")

    <<~PROMPT
      You design role-play practice scenes for a Japanese-language learning app.

      The learner uploaded real Japanese material. Topic summary: "#{upload.summary}"

      Vocabulary the material contains (a sample): #{words}

      Create a character and a situation grounded in that topic, so the
      learner's vocabulary comes up naturally in the conversation. Design
      AROUND the topic — do not quote the material.

      Return only JSON in exactly this shape:
      {"character_name": "Haruto", "persona": "...", "setting": "...", "description": "..."}

      Rules:
      - character_name: a common Japanese given name in romaji
      - persona: 2-3 sentences in English — who they are, their relationship
        to the learner, and how they speak (casual, polite, formal)
      - setting: a short English phrase naming the place or situation
        ("a neighborhood coin laundry")
      - description: 2-4 sentences in English — concrete details of the
        situation and why the two of them are talking
      - The situation must give the learner a reason to USE the vocabulary,
        not just hear it
    PROMPT
  end
end
