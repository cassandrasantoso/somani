module UploadsHelper
  # Renders extracted_text as safe HTML, wrapping any substring that
  # matches a seeded JlptEntry in a <mark> tag carrying its full data
  # (surface/reading/meaning/level), so clicking it can instantly fill
  # the save-word form below without needing another lookup.
  def highlight_jlpt_matches(text, entries)
    return "".html_safe if text.blank?
    return ERB::Util.html_escape(text) if entries.blank?

    pattern = Regexp.union(entries.map(&:content).sort_by { |c| -c.length })
    lookup = entries.index_by(&:content)

    html = +""
    last_end = 0

    text.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      html << ERB::Util.html_escape(text[last_end...match.begin(0)])
      entry = lookup[match[0]]
      html << %(<mark class="jlpt-match"
                       data-jlpt-entry-id="#{entry.id}"
                       data-level="#{entry.level}"
                       data-action="click->word-picker#selectMatch"
                       data-word-picker-surface-param="#{ERB::Util.html_escape(entry.content)}"
                       data-word-picker-reading-param="#{ERB::Util.html_escape(entry.reading)}"
                       data-word-picker-meaning-param="#{ERB::Util.html_escape(entry.meaning)}"
                       data-word-picker-level-param="#{ERB::Util.html_escape(entry.level)}"
                       data-bs-toggle="modal" data-bs-target="#exampleModal"
                       >#{ERB::Util.html_escape(match[0])}</mark>)
      last_end = match.end(0)
    end

    html << ERB::Util.html_escape(text[last_end..])
    html.html_safe
  end
end
