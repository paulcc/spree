class Admin::TaxonsController < Admin::BaseController
  include Railslove::Plugins::FindByParam::SingletonMethods
  resource_controller
  before_filter :load_object, :only => [:selected, :available, :remove]
  belongs_to :product
  
  create.wants.html {render :text => @taxon.id}
  update.wants.html {render :text => @taxon.name}
  destroy.wants.html {render :text => ""}
  
  create.before do 
    @taxon.taxonomy_id = params[:taxonomy_id]
  end
  
  update.before do
    parent_id = params[:taxon][:parent_id]
    position = params[:taxon][:position]

    if parent_id || position #taxon is being moved
      parent = parent_id.nil? ? @taxon.parent : Taxon.find(parent_id.to_i)
      position = position.nil? ? -1 : position.to_i 

      @taxon.move_to(parent, position)
      if parent_id
        @taxon.reload
        @taxon.permalink = nil
        @taxon.save!
        @update_children = true
      end
    end
    #check if we need to rename child taxons if parent name changes
    @update_children = params[:taxon][:name] == @taxon.name ? false : true
  end
  
  update.after do
    #rename child taxons                  
    if @update_children
      @taxon.descendents.each do |taxon|
        taxon.reload
        taxon.permalink = nil
        taxon.save!
      end
    end    
  end

  def selected 
    @taxons = @product.taxons
  end
  
  def available
    if params[:q].blank?
      @available_taxons = []
    else
      @available_taxons = Taxon.find(:all, :conditions => ['lower(name) LIKE ?', "%#{params[:q].downcase}%"])
    end
    @available_taxons.delete_if do |taxon| 
      @product.taxons.include?(taxon) ||
      !taxon.leaf? ||
      !(taxon.product_group.nil? || taxon.product_group.respond_to?(:<<))
    end
    respond_to do |format|
      format.html
      format.js {render :layout => false}
    end

  end
  
  def remove
    @taxon.product_group.remove(@product)
    @taxons = @product.taxons
    render :layout => false
  end  
  
  def select
    @product = Product.find_by_param!(params[:product_id])
    taxon = Taxon.find(params[:id])
    if taxon.product_group.nil?
      logger.debug("Setting up a new product group")
      list = ProductGroupList.new
      list.save
      group = ProductGroup.new(:name => taxon.permalink,
                               :group => list )
      group.save
      taxon.product_group = group
      taxon.save
      logger.debug("Taxon: #{taxon.inspect}")
    end
    logger.debug("Taxon: #{taxon.inspect}, #{taxon.product_group.inspect}")
    taxon.product_group << @product
    @taxons = @product.taxons
    render :layout => false
  end
  
  private 
  def reposition_taxons(taxons)
    taxons.each_with_index do |taxon, i|
        taxon.position = i
        taxon.save!
    end
  end
end
