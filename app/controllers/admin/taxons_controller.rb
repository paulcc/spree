class Admin::TaxonsController < Admin::BaseController
  include Railslove::Plugins::FindByParam::SingletonMethods
  resource_controller
  before_filter :load_object, :only => [:selected, :available]
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
  end
  
  def available
    if params[:taxon_id]
      # looking for available product groups to add to a taxon
      @taxon = Taxon.find(params[:taxon_id])
      
      if params[:q].blank?
        @available_product_groups = []
      else
        @available_product_groups = ProductGroup.find(:all, :conditions => ['lower(name) LIKE ?', "%#{params[:q].downcase}%"])
      end
#      respond_to do |format|
#        format.html
#        format.js { render :layout => false }
#      end
      render :action => :product_group_available,
             :layout => false
    end
  end
  
  def remove
    @taxon = Taxon.find(params[:taxon_id])
    @product_group = ProductGroup.find(params[:id])
    if @taxon.product_group == @product_group
      @taxon.product_group = nil
      @taxon.save
  end 

#    respond_to do |format|
#      format.html
#      format.js do 
        render :layout => false, 
               :partial => '/admin/taxonomies/taxon.html.erb', 
               :locals => { :taxon => @taxon }
#      end
#    end
  end  
  
  def select
    if params[:taxon_id]
      @taxon = Taxon.find(params[:taxon_id])
      @product_group = ProductGroup.find(params[:id])
      @taxon.product_group = @product_group unless @taxon.product_group
    end
#    respond_to do |format|
#      format.html
#      format.js do 
        render :layout => false, 
               :partial => '/admin/taxonomies/taxon.html.erb', 
               :locals => { :taxon => @taxon }
#      end
#    end

  end
  
end
