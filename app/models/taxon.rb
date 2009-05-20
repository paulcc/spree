class Taxon < ActiveRecord::Base
  include ProductSet

  acts_as_adjacency_list :foreign_key => 'parent_id', :order => 'position'
  belongs_to :taxonomy
#  has_and_belongs_to_many :products
  belongs_to :product_group
  before_save :set_permalink  

  validate :product_group_only_on_leaf_node
    
  def products
    self.leaf? ? product_group.products : cached_product_group.products
  end
  
  # This is--for you recursive types--a depth first traversal of
  # the taxonomy tree.  Union is associative, so we're all good.
  # Union of ordered sets is somewhat undefined, but we are not going
  # to treat that here.  That is going to be up to the ProductSet
  # module and the union method to handle...probably.
#  alias :ar_associated_product_group :product_group
#  def product_group
#    if self.leaf?
#      return ar_associated_product_group
#    else
#      @product_group = children.first.product_group
#      children[0..-2].each_index do |i|
#        @product_group = @product_group.union(children[i+1].product_group)
#      end
#      return @product_group
#    end
#  end

  private
  def set_permalink
    ancestors.reverse.collect { |ancestor| ancestor.name }.join( "/")
    prefix = ancestors.reverse.collect { |ancestor| escape(ancestor.name) }.join( "/")
    prefix += "/" unless prefix.blank?
    self.permalink =  prefix + "#{name.to_url}/"
  end
  
  # taken from the find_by_param plugin
  def escape(str)
    return "" if str.blank? # hack if the str/attribute is nil/blank
    s = Iconv.iconv('ascii//ignore//translit', 'utf-8', str.dup).to_s
    returning str.dup.to_s do |s|
      s.gsub!(/\ +/, '-') # spaces to dashes, preferred separator char everywhere
      s.gsub!(/[^\w^-]+/, '') # kill non-word chars except -
      s.strip!            # ohh la la
      s.downcase!         # :D
      s.gsub!(/([^ a-zA-Z0-9_-]+)/n,"") # and now kill every char not allowed.
    end
  end

  def product_group_only_on_leaf_node
    if !self.product_group.nil? && !self.leaf?
      error.add_to_base("Cannot assign a product group to a non leaf node taxon")
    end
  end

  private
  # This is--for you recursive types--a depth first traversal of
  # the taxonomy tree.  Union is associative, so we're all good.
  # Union of ordered sets is somewhat undefined, but we are not going
  # to treat that here.  That is going to be up to the ProductSet
  # module and the union method to handle...probably.
  def cached_product_group
    return @cached_product_group if  @cached_product_group && @valid_product_group_cache

    @cached_product_group = children.first.product_group
    children[0..-2].each_index do |i|
      @cached_product_group = @cached_product_group.union(children[i+1].product_group)
    end
    @valid_product_group_cache = true
    return @cached_product_group
  end

end
