# This module implements the product-set interface
# it requires a products methods that returns an array
# of products
module ProductSet
  def union(other)
    result = products + other.products
    result.uniq!
    ProductGroupEphemeral.new(result)
  end

  def intersect(other)
    result = []
    products.each do |p|
      result << p if other.products.member?(p)
    end
    ProductGroupEphemeral.new(result)
  end

  def complement(other)
    ProductGroupEphemeral.new(products - other.products)
  end

  # properly known as the symmetric difference
  # see http://en.wikipedia.org/wiki/Symmetric_difference
  def xor(other)
    self.complement(other).union(other.complement(self))
  end
end

class ProductGroupEphemeral
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
