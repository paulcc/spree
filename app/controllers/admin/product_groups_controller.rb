class Admin::ProductGroupsController < Admin::BaseController
  resource_controller

  before_filter :load_product_group_with_render, :only => [:selected, :available]
  before_filter :load_product_group_and_product_with_render, :only => [:remove, :select]

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
    return unless @product_group && @product
    @product_group.remove(@product)
    render :partial => @product_group.view_name(:product_table), 
           :locals => {:product_group => @product_group}, 
           :layout => !request.xhr?
  end

  def selected
    return unless @product_group
    @products = @product_group.products
    render :action => @product_group.view_name(:selected)
  end
  
  def available
    return unless @product_group
    if params[:q].blank?
      @available_products = []
    else
      @available_products = Product.find(:all, :conditions => ['lower(name) LIKE ?', "%#{params[:q].downcase}%"])
    end
    @available_products.delete_if { |product| @product_group.products.include? product }
    render :action => @product_group.view_name(:available), :layout => !request.xhr?
  end

  def select
    return unless @product_group && @product
    if @product_group.respond_to? :<<
        @product_group << @product 
    end
    render :partial => @product_group.view_name(:product_table), 
           :locals => {:product_group => @product_group}, 
           :layout => !request.xhr?
  end

  private
  def load_product_group_with_render
    @product_group = ProductGroup.find_by_id(params[:product_group_id]) if params[:product_group_id]
    render(:text => t("missing_product_group_error"), :status => 404) unless @product_group
  end

  def load_product_group_and_product_with_render
    errors = Array.new
    @product_group = ProductGroup.find_by_id(params[:product_group_id]) if params[:product_group_id]
    errors << t("missing_product_group_error") unless @product_group

    @product = Product.find_by_permalink(params[:id]) if params[:id]
    errors << t("missing_product_error") unless @product

    render(:partial => '/admin/shared/errors', 
           :locals => {:errors => errors}, 
           :status => 404) unless @product_group && @product
  end


end
