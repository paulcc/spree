class Taxon < ActiveRecord::Base
  include ProductSet

  acts_as_adjacency_list :foreign_key => 'parent_id', :order => 'position'
  belongs_to :taxonomy
  belongs_to :product_group
  before_save :set_permalink  
  after_validation_on_update :update_permalinks_on_name_change

  validate :product_group_only_on_leaf_node
  validate :parent_has_no_product_group
    
  def products
    cached_product_group.products
  end

  def move_to!(new_parent, new_position)
    # if the taxon is switching parents, then it needs to update
    # its permalink and the permalink of all of its children
    reset_permalinks = new_parent != self.parent 
    super 
    if reset_permalinks
      self.set_permalink.save!
      self.descendents.each do |taxon|
       taxon.set_permalink.save!
      end
    end
    self
  end

  protected
  def set_permalink
    ancestors.reverse.collect { |ancestor| ancestor.name }.join( "/")
    prefix = ancestors.reverse.collect { |ancestor| escape(ancestor.name) }.join( "/")
    prefix += "/" unless prefix.blank?
    self.permalink =  prefix + "#{name.to_url}/"
  end

  # This is--for you recursive types--a depth first traversal of
  # the taxonomy tree.  Union is associative, so we're all good.
  # Union of ordered sets is somewhat undefined, but we are not going
  # to treat that here.  That is going to be up to the ProductSet
  # module and the union method to handle...probably.
  def cached_product_group
    return @cached_product_group if @cached_product_group && valid_product_group_cache

    @cached_product_group = self.product_group || ProductGroupEphemeral.new([])
    return @cached_product_group if self.leaf?
    
    children.each do |child|
      @cached_product_group = @cached_product_group.union(child.cached_product_group)
    end

    return @cached_product_group
  end

  private
  def update_permalinks_on_name_change    # PCC keep? 
    if name_changed?
      set_permalink
      descendents.each { |taxon| taxon.set_permalink.save }
    end
  end
  
  # taken from the find_by_param plugin
  def escape(str)
    return "" if str.blank? # hack if the str/attribute is nil/blank
    str = Iconv.iconv('ascii//ignore//translit', 'utf-8', str.dup).to_s
    returning str.dup.to_s do |s|
      s.gsub!(/\ +/, '-') # spaces to dashes, preferred separator char everywhere
      s.gsub!(/[^\w^-]+/, '') # kill non-word chars except -
      s.strip!            # ohh la la
      s.downcase!         # :D
      s.gsub!(/([^ a-zA-Z0-9_-]+)/n,"") # and now kill every char not allowed.
    end
  end

  def product_group_only_on_leaf_node
    if self.product_group && !self.leaf?
      errors.add_to_base("Cannot assign a product group to a non leaf node taxon")
    end
  end

  def parent_has_no_product_group
    if self.parent && self.parent.product_group
      errors.add_to_base("Cannot assign child taxon to a taxon which already has a product group")
    end
  end


  def valid_product_group_cache
    return false
  end

end
