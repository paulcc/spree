class Calculator::FlexiRate < Calculator
  preference :first_item,      :decimal, :default => 0
  preference :additional_item, :decimal, :default => 0
  preference :max_items,       :decimal, :default => 0

  def self.description
    I18n.t("flexible_rate")
  end

  def self.available?(object)
    true
  end

  def self.register
    super
    Coupon.register_calculator(self)
    ShippingMethod.register_calculator(self)
    ShippingRate.register_calculator(self)
  end

  def compute(order)
    return if order.nil?
    compute_from_quantity(order.line_items.map(&:quantity).sum)
  end

  def compute_from_quantity(item_count)
    max = self.preferred_max_items
    result = 0
    if max > 0
      result = [max,item_count].min * self.preferred_first_item 
    end
    result += [item_count - max, 0].max * self.preferred_additional_item

    return result
  end  
end
