class ProductGroup < ActiveRecord::Base
  belongs_to :group, :polymorphic => true
  has_many :taxons

  include ProductSet

  def products
    group.products
  end

  def respond_to?(symbol, include_priv = false)
    logger.debug("product_group.respond_to?")
    if ProductGroup::registered_method?(group.class, symbol)
    logger.debug("product_group.respond_to? -- true")
      return true
    else
      return super(symbol, include_priv)
    end
  end

  # Give the polymorphic class a shot at it
  def method_missing(method_id, *args)
    if ProductGroup::registered_method?(group.class, method_id)
      return group.send(method_id, *args)
    else
      return super(method_id, *args)
    end
  end

  @@registered_methods_by_class = {}

  def self.register_method(poly_subclass, method_id)
    @@registered_methods_by_class[poly_subclass] ||= {}
    @@registered_methods_by_class[poly_subclass][method_id] = true
  end

  protected
  def self.registered_method?(poly_subclass, method_id)
    logger.debug("method_id: #{method_id.inspect}")
    logger.debug("#{@@registered_methods_by_class.inspect}")
    return @@registered_methods_by_class[poly_subclass] && 
      @@registered_methods_by_class[poly_subclass][method_id]
  end
end

