# This module implements the product-set interface
module ProductSet
#  def [](*p)
#    products[*p]
#  end

#  def ==(other)
#    products == other.products
#  end

  def union(other)
    result = products + other.products
    result.uniq!
    ProductGroupAnonymous.new(result)
  end

  def intersect(other)
    result = []
    products.each do |p|
      result << p if other.products.member?(p)
    end
    ProductGroupAnonymous.new(result)
  end

  def complement(other)
    ProductGroupAnonymous.new(products - other.products)
  end

  # properly known as the symmetric difference
  # see http://en.wikipedia.org/wiki/Symmetric_difference
  def xor(other)
    self.complement(other).union(other.complement(self))
  end

#  def method_missing(method_id, *args, &block)
#    if products.respond_to? method_id
#      return products.send(method_id, *args, &block)
#    else
#      return super
#    end
#  end

end

class ProductGroupAnonymous
  include ProductSet

  def initialize(products = [])
    @products = products
  end

  def products
    @products
  end

  def name
  end
end
