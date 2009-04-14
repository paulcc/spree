class CreateProductGroupListNodes < ActiveRecord::Migration
  def self.up
    create_table :product_group_list_nodes do |t|
      t.integer :position, :default => 0, :null => false
      t.integer :product_group_list_id, :null => false
      t.integer :product_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :product_group_list_nodes
  end
end
