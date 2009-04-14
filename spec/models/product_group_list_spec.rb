require File.dirname(__FILE__) + '/../spec_helper'

module ProductGroupListSpecHelper
  def prod_list_a 
    list_a = %w{
      ruby-on-rails-tote
      ruby-on-rails-bag
      ruby-on-rails-baseball-jersey }
    list_a.collect { |pl| Product.find_by_permalink(pl) }
  end

  def prod_list_b 
    list_b = %w{
      ruby-on-rails-tote
      ruby-on-rails-bag
      ruby-on-rails-mug
      ruby-on-rails-ringer-t-shirt  }
    list_b.collect { |pl| Product.find_by_permalink(pl) }
  end
  
  def prod_list_b
    list_c = %w{
      ruby-on-rails-stein
      ruby-on-rails-bag
      ruby-on-rails-mug }
    list_c.collect { |pl| Product.find_by_permalink(pl) }
  end

end

describe ProductGroupList do
  include ProductGroupListSpecHelper

  before(:each) do
    @list = ProductGroupList.new
    @prod = Product.find_by_permalink('apache-baseball-jersey')
  end

  it "should initialize with an empty list" do
    @list.products.should be_empty
  end
  it "should allow products to be appended to the list" do
    @list << prod_list_a
    @list.products.should == prod_list_a
    @list << @prod
    @list.products.should == prod_list_a + [@prod]
  end
  it "should allow product to be inserted into the list" do
    pending "I'll implement this some day"
  end
  it "should allow products to be re-ordered in the list" do
    pending "acts as list can already do this, I just need to hook it up"
  end
  it "should not be possible to have the same product in the list more than once" do
    @list << @prod << @prod
    @list.products.should == [@prod]
  end
end
