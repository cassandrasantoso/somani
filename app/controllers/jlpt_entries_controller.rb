class JlptEntriesController < ApplicationController
  def index
    scope = policy_scope(JlptEntry)
            .by_level(params[:level])
            .by_type(params[:entry_type])
            .search(params[:q])

    @total = scope.count # before .limit — count of ALL matches
    @page  = [params[:page].to_i, 1].max

    @jlpt_entries = scope.order(:level, :content)
                         .limit(50)
                         .offset((@page - 1) * 50)
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

    if params[:level].blank?
      return redirect_to(jlpt_entries_path,
                         alert: "Choose a level before importing.")
    end

    entries = policy_scope(JlptEntry)
              .by_level(params[:level])
              .by_type(params[:entry_type])

    now  = Time.current
    rows = entries.map do |e|
      { user_id: current_user.id, surface: e.content, reading: e.reading,
        meaning: e.meaning, level: e.level, jlpt_entry_id: e.id,
        created_at: now, updated_at: now }
    end

    return redirect_to(jlpt_entries_path, alert: "Nothing to import.") if rows.empty?

    # One INSERT instead of 3,303 round trips. `unique_by` leans on the
    # [user_id, surface] unique index to skip words already saved — which is
    # why that index matters beyond correctness.
    inserted = SavedWord.insert_all(rows,
                                    unique_by: %i[user_id surface],
                                    returning: %w[id]).count

    redirect_to saved_words_path,
                notice: "Added #{inserted} words " \
                        "(#{rows.size - inserted} already in your list)."
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
