class AddFileLocationToUpload < ActiveRecord::Migration[8.1]
  def change
    add_column :uploads, :file_location, :string
  end
end
