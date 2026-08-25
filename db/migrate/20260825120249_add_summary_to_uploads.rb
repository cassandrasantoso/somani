class AddSummaryToUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :uploads, :summary, :text
  end
end
