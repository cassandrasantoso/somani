# One definition of "does this text contain this word", shared by the usage
# ledger and the correction index. Two definitions would mean the tracker and
# the corpus disagree about the same sentence.
#
# Deterministic first pass. ModelWordMatcher is the paid second pass for the
# irregulars this cannot reach.
module ConjugationMatcher
  # Bare する and 来る are exact-match only: any string short enough to
  # identify them (し, した, して) also appears in the polite forms of every
  # other verb — 食べました contains した.
  IRREGULAR = %w[する くる 来る].freeze

  # Ichidan: the stem plus whatever can follow it.
  # 食べる → 食べ, 食べま(す), 食べた, 食べれ(ば), 食べら(れる)…
  ICHIDAN_BASES = %w[る ま た て な れ ら さ よ].freeze

  # Godan: the final kana shifts within its row. い/っ/ん cover the sound
  # changes in the past and te-forms (書いた, 行った, 飲んだ).
  GODAN_BASES = {
    "う" => %w[わ い う え お っ],
    "く" => %w[か き く け こ い っ],
    "ぐ" => %w[が ぎ ぐ げ ご い],
    "す" => %w[さ し す せ そ],
    "つ" => %w[た ち つ て と っ],
    "ぬ" => %w[な に ぬ ね の ん],
    "ぶ" => %w[ば び ぶ べ ぼ ん],
    "む" => %w[ま み む め も ん],
    "る" => %w[ら り る れ ろ っ]
  }.freeze

  # 高い → 高い, 高く(て), 高かっ(た), 高けれ(ば)
  I_ADJ_BASES = %w[い く かっ けれ].freeze

  # Compound する-verbs: 出席する → 出席し, 出席す, 出席さ, 出席せ
  SURU_BASES = %w[する し す さ せ].freeze

  module_function

  def match?(text, word)
    body = text.to_s
    return false if body.blank?

    forms(word).any? { |b| body.include?(b) }
  end

  # Three spellings (saved form, reading, dictionary form), each expanded
  # into conjugation bases —> so 行きました matches 行く.
  def forms(word)
    [word.surface, word.reading, word.jlpt_entry&.content]
      .compact_blank.uniq
      .flat_map { |f| bases(f) }
      .uniq
  end

  # The 2+ character strings any inflected form of `form` must start with.
  # Rules are applied additively, not exclusively — a form that isn't a real
  # word just never matches, so guessing wrong costs a miss, not a false credit.
  def bases(form)
    return [form] if IRREGULAR.include?(form)

    out = [form]

    if form.end_with?("する")
      root = form.delete_suffix("する")
      out += SURU_BASES.map { |b| root + b } if root.present?
    end

    if form.end_with?("る")
      root = form.delete_suffix("る")
      out << root
      out += ICHIDAN_BASES.map { |b| root + b }
    end

    if (row = GODAN_BASES[form[-1]])
      root = form[0..-2]
      out += row.map { |k| root + k }
    end

    if form.end_with?("い")
      root = form.delete_suffix("い")
      out += I_ADJ_BASES.map { |b| root + b }
    end

    # the word itself always counts, whatever its length; only generated
    # bases need the 2-character floor
    out.uniq.select { |b| b == form || b.length >= 2 }
  end
end
