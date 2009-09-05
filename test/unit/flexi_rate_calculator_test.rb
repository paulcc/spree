require 'test_helper'
class FlexiRateCalculatorTest < ActiveSupport::TestCase
  context "Calculator::FlexiRate" do
    [Coupon, ShippingMethod, ShippingRate].each do |calculable| 
      should "be available to #{calculable.to_s}" do
       assert calculable.calculators.include?(Calculator::FlexiRate)
      end
    end
    should "not be available to TaxRate" do
      assert !TaxRate.calculators.include?(Calculator::FlexiRate)
    end

    context "compute" do
      setup do
        @order = Factory(:order)
        @calculator = Calculator::FlexiRate.new(:preferred_max_items => 10, :preferred_first_item => 2, :preferred_additional_item => 1)
        @product = Factory(:product)
        @var_one = Factory(:variant, :product => @product)
        @var_two = Factory(:variant, :product => @product)
      end

      context "empty order" do
        setup do 
          @order.line_items = []
        end
        should "return zero" do
          assert_equal 0, @calculator.compute(@order)
        end
      end       

      context "for order beneath max threshold" do
        setup do 
          @order.line_items = [Factory(:line_item, :variant => @var_one, :quantity => 4),
                               Factory(:line_item, :variant => @var_two, :quantity => 4)]
        end
        should "return expected result" do
          assert_equal (8 * 2), @calculator.compute(@order)
        end
      end       

      context "for order above max threshold" do
        setup do 
          @order.line_items = [Factory(:line_item, :variant => @var_one, :quantity => 6),
                               Factory(:line_item, :variant => @var_two, :quantity => 6)]
        end
        should "return expected result" do
          assert_equal (10 * 2 + 2 * 1), @calculator.compute(@order)
        end
      end       
    end
  end
end
