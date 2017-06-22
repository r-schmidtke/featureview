class AddVersionExtraField < ActiveRecord::Migration
  def change
    add_column :versions, :extra, :string
  end
end
