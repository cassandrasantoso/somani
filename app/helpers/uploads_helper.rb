module UploadsHelper
  # Renders extracted_text as safe HTML, wrapping any substring that
  # matches a seeded JlptEntry in a <mark> tag with the entry's id/level
  # attached, so matched words render highlighted on the page.
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
      html << %(<mark class="jlpt-match" data-jlpt-entry-id="#{entry.id}" data-level="#{entry.level}">#{ERB::Util.html_escape(match[0])}</mark>)
      last_end = match.end(0)
    end

    html << ERB::Util.html_escape(text[last_end..])
    html.html_safe
  end
end
