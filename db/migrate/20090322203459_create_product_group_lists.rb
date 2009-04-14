class CreateProductGroupLists < ActiveRecord::Migration
  def self.up
    create_table :product_group_lists do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :product_group_lists
  end
end
