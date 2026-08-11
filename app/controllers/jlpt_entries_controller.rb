class JlptEntriesController < ApplicationController
  def index
    @jlpt_entries = policy_scope(JlptEntry)
                    .by_level(params[:level]).by_type(params[:entry_type])
  end

  def show
    @jlpt_entry = JlptEntry.find(params[:id])
    authorize @jlpt_entry
  end

  def save
    @jlpt_entry = JlptEntry.find(params[:id])
    authorize @jlpt_entry, :show?
    import([@jlpt_entry])
    redirect_to jlpt_entries_path, notice: "Added to your words."
  end

  def bulk_save
    authorize JlptEntry, :show?
    entries = JlptEntry.by_level(params[:level]).by_type(params[:entry_type])
    import(entries)
    redirect_to saved_words_path, notice: "#{entries.size} entries imported."
  end

  private

  # Imported words have no upload, so before saved_words.user_id existed,
  # these rows were unreachable by every policy scope in the app.
  def import(entries)
    entries.each do |entry|
      current_user.saved_words.find_or_create_by!(surface: entry.content) do |w|
        w.reading = entry.reading
        w.level   = entry.level
        w.meaning = entry.meaning
        w.jlpt_entry = entry
      end
    end
  end
end
