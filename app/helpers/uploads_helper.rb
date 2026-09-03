module UploadsHelper
  KATAKANA = /[\p{Katakana}ー]/
  KANJI    = /\p{Han}/

  # Renders extracted_text as safe HTML, wrapping any substring that
  # matches a seeded JlptEntry in a <mark> tag carrying its full data
  # (surface/reading/meaning/level), so clicking it can instantly fill
  # the save-word form below without needing another lookup.
  def highlight_jlpt_matches(text, entries)
    return "".html_safe if text.blank?
    return ERB::Util.html_escape(text) if entries.blank?

    pattern = Regexp.union(entries.map(&:content).sort_by { |c| -c.length })
    # Deterministic winner among duplicate surfaces.
    # index_by silently kept whichever row the unordered relation happened to return last,
    # so the same word could show a different level between page loads
    # and the modal would prefill a different reading and meaning with it.
    lookup = entries.sort_by { |e| [e.level.to_s, e.id] }.index_by(&:content)

    html = +""
    last_end = 0

    text.to_enum(:scan, pattern).each do
      m = Regexp.last_match
      next if fragment?(text, m[0], m.begin(0), m.end(0))

      html << ERB::Util.html_escape(text[last_end...m.begin(0)])
      entry = lookup[m[0]]
      html << %(<mark class="jlpt-match"
                       data-jlpt-entry-id="#{entry.id}"
                       data-level="#{entry.level}"
                       data-action="click->word-picker#selectMatch"
                       data-word-picker-surface-param="#{ERB::Util.html_escape(entry.content)}"
                       data-word-picker-reading-param="#{ERB::Util.html_escape(entry.reading)}"
                       data-word-picker-meaning-param="#{ERB::Util.html_escape(entry.meaning)}"
                       data-word-picker-level-param="#{ERB::Util.html_escape(entry.level)}"
                       data-bs-toggle="modal" data-bs-target="#exampleModal"
                       >#{ERB::Util.html_escape(m[0])}</mark>)
      last_end = m.end(0)
    end

    html << ERB::Util.html_escape(text[last_end..])
    html.html_safe
  end

  private

  # A match only counts as a word if its edges land on a script boundary.
  # Kanji is checked only at length 1:
  # multi-character kanji words legitimately adjacent to other kanji constantly (回転 next to 寿司),
  # so only a lone kanji is a reliable sign of a fragment.
  def fragment?(text, matched, start_pos, end_pos)
    before = start_pos.positive? ? text[start_pos - 1].to_s : ""
    after  = text[end_pos].to_s

    return true if matched.match?(KATAKANA) &&
                   (before.match?(KATAKANA) || after.match?(KATAKANA))

    return true if matched.length == 1 && matched.match?(KANJI) &&
                   (before.match?(KANJI) || after.match?(KANJI))

    false
  end
end
