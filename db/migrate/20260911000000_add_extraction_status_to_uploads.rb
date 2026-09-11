class AddExtractionStatusToUploads < ActiveRecord::Migration[8.1]
  def up
    add_column :uploads, :extraction_status, :string, default: "pending", null: false

    execute "UPDATE uploads SET extraction_status = 'ready'"
  end

  def down
    remove_column :uploads, :extraction_status
  end
end
