class AddTitleToUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :uploads, :title, :string
  end
end
