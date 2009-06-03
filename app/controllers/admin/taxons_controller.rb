class Admin::TaxonsController < Admin::BaseController
  include Railslove::Plugins::FindByParam::SingletonMethods
  resource_controller
  before_filter :load_object, :only => [:update]
  before_filter :load_taxon_with_render, :only => [:available]
  before_filter :load_taxon_and_product_group_with_render, :only => [:remove, :select]
  
  create.wants.html {render :text => @taxon.id}
  destroy.wants.html {render :text => "" }
    
  create.before do 
    @taxon.taxonomy_id = params[:taxonomy_id]
  end
  
  def update
    parent_id = params[:taxon].delete(:parent_id)
    position = params[:taxon].delete(:position)

    if parent_id || position #taxon is being moved
      parent = @taxon.parent
      if parent_id
        parent = Taxon.find_by_id(parent_id.to_i)
        unless parent
          render :text => t("missing_parent_error"), :status => 404
          return
        end
      end

      position = position.nil? ? -1 : position.to_i 

      begin
        @taxon.move_to!(parent, position)
      rescue ActiveRecord::RecordInvalid => e
        render :partial => 'admin/shared/errors.html.erb', 
               :status => 400, 
               :locals => {:errors => e.record.errors.full_messages}
        return
     end
    end

    @taxon.update_attributes!(params[:taxon])

    respond_to do |format| 
      format.html { render :text => @taxon.name }
    end
  end
  
  def available
    return unless @taxon
    if params[:q].blank?
      @available_product_groups = []
    else
      @available_product_groups = ProductGroup.find(:all, :conditions => ['lower(name) LIKE ?', "%#{params[:q].downcase}%"])
    end
    render :action => :product_group_available, :layout => !request.xhr?
  end
  
  def remove
    return unless @taxon && @product_group      
    if @taxon.product_group == @product_group
      @taxon.product_group = nil
      save_taxon
    else
      render :text => t("target_product_group_not_assigned_to_taxon_error"), :status => 409
    end 
  end  
  
  def select
    return unless @taxon && @product_group
    if @taxon.product_group
      render :text => t("target_taxon_already_has_product_group_error"), :status => 409
    else
      @taxon.product_group = @product_group
      save_taxon
    end
  end

  private
  def load_taxon_with_render
    @taxon = Taxon.find_by_id(params[:taxon_id]) if params[:taxon_id]
    render(:text => t("missing_taxon_error"), :status => 404) unless @taxon
  end
  
  def load_taxon_and_product_group_with_render
    errors = Array.new
    @taxon = Taxon.find_by_id(params[:taxon_id]) if params[:taxon_id]
    errors << t("missing_taxon_error") unless @taxon

    @product_group = ProductGroup.find_by_id(params[:id]) if params[:id]
    errors << t("missing_product_group_error") unless @product_group

    render(:partial => '/admin/shared/errors', 
           :locals => {:errors => errors}, 
           :status => 404) unless @taxon && @product_group
  end

  def save_taxon
    begin
      @taxon.save!
    rescue ActiveRecord::RecordInvalid => e
      render :layout => !request.xhr?, 
             :partial => 'admin/shared/errors.html.erb', 
             :status => 400, 
             :locals => {:errors => e.record.errors.full_messages}
    else
      render :layout => !request.xhr?, 
             :partial => '/admin/taxonomies/taxon.html.erb', 
             :locals => { :taxon => @taxon }
    end
  end
  
end
