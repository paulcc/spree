class CreateProductGroups < ActiveRecord::Migration
  def self.up
    create_table :product_groups do |t|
      t.string :name, :null => false
      t.integer :group_id, :null => false
      t.string :group_type, :null => false
      t.boolean :anonymous, :default=> true, :null => false 
      t.timestamps
    end
  end

  def self.down
    drop_table :product_groups
  end
end
