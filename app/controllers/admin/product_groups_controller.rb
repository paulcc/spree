class Admin::ProductGroupsController < Admin::BaseController
  resource_controller

  before_filter :load_object, :only => [:selected, :available]

  new_action.response do |wants|
    wants.html {render :action => :new, :layout => false}
  end

  # redirect to index (instead of r_c default of show view)
  update.response do |wants| 
    wants.html {redirect_to collection_url}
  end
  
  # redirect to index (instead of r_c default of show view)
  create.response do |wants| 
    wants.html {redirect_to collection_url}
  end

  def remove
    partial = 'product_group_remove'
    if params[:product_group_id]
      @product_group = ProductGroup.find(params[:product_group_id])
      product = Product.find_by_permalink(params[:id])
      @product_group.remove(product)
      partial = "#{@product_group.group_type.underscore}_product_table"
    end

    render :partial => partial, :locals => {:product_group => @product_group}, :layout => false
  end

  def selected
    if params[:product_group_id]
      @product_group = ProductGroup.find(params[:product_group_id])
      @products = @product_group.products
      render :action => "#{@product_group.group_type.underscore}_selected"
    end
  end
  
  def available
    if params[:product_group_id]
      # looking for products available to add to this product group
      @product_group = ProductGroup.find(params[:product_group_id])
      if params[:q].blank?
        @available_products = []
      else
        @available_products = Product.find(:all, :conditions => ['lower(name) LIKE ?', "%#{params[:q].downcase}%"])
      end
      @available_products.delete_if { |product| @product_group.products.include? product }
      respond_to do |format|
        format.html
        format.js {render :action => "#{@product_group.group_type.underscore}_available", :layout => false}
      end
    end
  end

  def select
    if params[:product_group_id]
      @product_group = ProductGroup.find(params[:product_group_id])
      @product = Product.find_by_permalink(params[:id])
      if @product_group.respond_to? :<<
          @product_group << @product 
      end
      render :partial => "#{@product_group.group_type.underscore}_product_table", :locals => {:product_group => @product_group}
    end
  end

end
