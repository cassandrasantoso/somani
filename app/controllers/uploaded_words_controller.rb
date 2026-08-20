class UploadedWordsController < ApplicationController
  # Removes a word from ONE upload. The word itself survives.
  def destroy
    @uploaded_word = UploadedWord.find(params[:id])
    authorize @uploaded_word
    @upload = @uploaded_word.upload
    @uploaded_word.destroy

    @saved_words = @upload.saved_words
    @matched_entries = @upload.matched_jlpt_entries
    @already_saved_surfaces = current_user.saved_words.pluck(:surface)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @upload, status: :see_other }
    end
  end
end
