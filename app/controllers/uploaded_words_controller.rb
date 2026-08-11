class UploadedWordsController < ApplicationController
  # Removes a word from ONE upload. The word itself survives.
  def destroy
    @uploaded_word = UploadedWord.find(params[:id])
    authorize @uploaded_word
    upload = @uploaded_word.upload
    @uploaded_word.destroy
    redirect_to upload, status: :see_other
  end
end
