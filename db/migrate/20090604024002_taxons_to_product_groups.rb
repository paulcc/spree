class TaxonsToProductGroups < ActiveRecord::Migration
  def self.up
    Taxon.find(:all).each do |taxon|
      # the taxon <-> product association got whacked during the upgrade
      # so we are going to have to do this the old fashioned way
      sql = "select p.* from products p join products_taxons on p.id=product_id where taxon_id=#{taxon.id}"
      products = Product.connection.select_all(sql).collect {|p| Product.new(p)}

      if products.length
        if taxon.leaf?
        # create new product group
          pg = ProductGroup.new({ :name => taxon.permalink,
                                  :group_type => :ProductGroupList })
          pg.save!
          taxon.product_group = pg
          taxon.save!
          products.each {|p| pg << p}
        else
          # these products are going to get abandoned
          products.each do |product|
            write "Product #{product.id} - #{product.permalink} cannot be assigned to Taxon #{taxon.name} bacause it is not a leaf node"
          end
        end
      end
    end
 #    drop_table :products_taxons
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
