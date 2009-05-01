class Admin::ProductGroupsController < Admin::BaseController
  resource_controller

  before_filter :load_object, :only => [:selected, :available, :remove]

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
    if params[:product_id]
      product = Product.find_by_param!(params[:product_id])
      @product_group.remove(product)
      partial = "admin/shared/#{@product_group.group_type.underscore}_product_table"
    end

    render :partial => partial, :locals => {:product_group => @product_group}, :layout => false
  end

  def selected
  end
  
  def available
  end

end
