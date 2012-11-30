class AddParentIdToDirectories < ActiveRecord::Migration
  def change
    add_column :directories, :parent_id, :integer
    add_index :directories, :parent_id
  end
end
