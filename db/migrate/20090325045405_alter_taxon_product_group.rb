class AlterTaxonProductGroup < ActiveRecord::Migration
  def self.up
    add_column :taxons, :product_group_id, :integer
  end

  def self.down
    remove_column :taxons, :product_group_id
  end
end
