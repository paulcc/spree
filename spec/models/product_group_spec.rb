require File.dirname(__FILE__) + '/../spec_helper'

module ProductGroupSpecHelper
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
      ruby-on-rails-mug
      ruby-on-rails-ringer-t-shirt
      ruby-on-rails-bag  }
    list_b.collect { |pl| Product.find_by_permalink(pl) }
  end
  
  def prod_list_c
    list_c = %w{
      ruby-on-rails-stein
      ruby-on-rails-bag
      ruby-on-rails-mug }
    list_c.collect { |pl| Product.find_by_permalink(pl) }
  end

end

describe ProductGroup do
  include ProductGroupSpecHelper
  
  before(:each) do
    @pg_list_a = ProductGroupList.new
    @pg_list_a << prod_list_a
    @pg_list_b = ProductGroupList.new
    @pg_list_b << prod_list_b
  end

  it "should allow creation of a product group" do
    pg = ProductGroup.new(:group => @pg_list_a)
    pg.products.should == prod_list_a
  end

  it "should union two groups together" do
    pg_a = ProductGroup.new(:group => @pg_list_a)
    pg_b = ProductGroup.new(:group => @pg_list_b)

    expect = prod_list_a + prod_list_b
    expect.uniq!
    pg_a.union(pg_b).products.should == expect
  end
  
  it "should intersect two groups together" do
    pg_a = ProductGroup.new(:group => @pg_list_a)
    pg_b = ProductGroup.new(:group => @pg_list_b)

    expect = %w{ 
      ruby-on-rails-tote
      ruby-on-rails-bag }.collect { |pl| Product.find_by_permalink(pl) }

    pg_a.intersect(pg_b).products.should == expect
  end

  it "should subtract two groups" do
    pg_a = ProductGroup.new(:group => @pg_list_a)
    pg_b = ProductGroup.new(:group => @pg_list_b)

    expect = prod_list_a - prod_list_b
    pg_a.complement(pg_b).products.should == expect
  end

  it "should do symmetric differece a couple of different ways" do
    pg_a = ProductGroup.new(:group => @pg_list_a)
    pg_b = ProductGroup.new(:group => @pg_list_b)

    expect_one_way = %w{
      ruby-on-rails-baseball-jersey
      ruby-on-rails-mug
      ruby-on-rails-ringer-t-shirt }.collect { |pl| Product.find_by_permalink(pl) } 

    pg_a.xor(pg_b).products.should == expect_one_way

    another_way = pg_a.union(pg_b).complement(pg_a.intersect(pg_b))
    pg_a.xor(pg_b).products.should == another_way.products
  end
end
