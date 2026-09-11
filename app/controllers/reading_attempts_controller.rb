class ReadingAttemptsController < ApplicationController
  def create
    @passage = ReadingPassage.find(params[:reading_passage_id])
    authorize @passage.upload, :show?

    answers = Array(params[:answers]).map(&:to_i)
    comprehension = score(answers, @passage)
    duration_ms = params[:duration_ms].to_i
    mode = params[:mode] == "listening" ? :listening : :reading
    wpm = if mode == :listening
            nil
          else
            duration_ms.positive? ? (@passage.char_count / (duration_ms / 60_000.0)).round : 0
          end

    @attempt = current_user.reading_attempts.build(
      reading_passage: @passage,
      duration_ms: duration_ms,
      wpm: wpm,
      comprehension: comprehension,
      mode: mode
    )

    if @attempt.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to reading_passage_path(@passage), notice: "Attempt saved." }
      end
    else
      redirect_to reading_passage_path(@passage), alert: "Could not save the attempt."
    end
  end

  private

  # Never trust the client's score — the questions and correct answers live
  # on the passage, so the server grades.
  def score(answers, passage)
    return 0 if answers.empty?

    correct = passage.questions.each_with_index.count { |question, index| answers[index] == question["answer"] }
    (correct * 100 / passage.questions.size).round
  end
end
