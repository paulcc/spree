class ProductGroupList < ActiveRecord::Base
  has_one :product_group, :as => :group
  has_many :product_group_list_nodes, :order => 'position'
#  has_many :products, :through => :product_group_list_nodes

#  def each(b)
#    product_group_list_nodes.each(b)
#  end

#  def [](*p)
#    product_group_list_nodes[*p]
#  end

  def <<(obj)
    obj = [obj] if obj.is_a? Product

    if obj.is_a? Array
      obj.each do |p|
        unless products.include? p
          product_group_list_nodes << ProductGroupListNode.new( :product => p )
        end
      end
    else
      raise ArgumentError("Invalid argument")
    end
    self
  end

  def products
    product_group_list_nodes.collect {|n| n.product}
  end

end
