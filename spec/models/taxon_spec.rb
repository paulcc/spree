require File.dirname(__FILE__) + '/../spec_helper'

module TaxonHelper
  def valid_taxon_attributes
    {
      :name => "A Taxon",
      :position => 1
    }
  end
end

describe Taxon do
  include TaxonHelper

  before(:each) do
    @taxonomy = Taxonomy.create(:name => "Test")
    @taxon = Taxon.new
    
     @ty = Taxonomy.create(:name => "tree")
     
    @t_root = Taxon.create({:taxonomy => @ty, :name => 't_root', :position => 0})
    @t_a0 = Taxon.create({:taxonomy => @ty, :name => 't_a0', :parent => @t_root, :position => 0})
    @t_a1 = Taxon.create({:taxonomy => @ty, :name => 't_a1', :parent => @t_root, :position => 1})
    @t_a2 = Taxon.create({:taxonomy => @ty, :name => 't_a2', :parent => @t_root, :position => 2})    
    @t_a3 = Taxon.create({:taxonomy => @ty, :name => 't_a3', :parent => @t_root, :position => 3})

    @t_b0 = Taxon.create({:taxonomy => @ty, :name => 't_b0', :parent => @t_a1, :position => 0})
    @t_b1 = Taxon.create({:taxonomy => @ty, :name => 't_b1', :parent => @t_a1, :position => 1})
    @t_b2 = Taxon.create({:taxonomy => @ty, :name => 't_b2', :parent => @t_a1, :position => 2})    

    @t_c0 = Taxon.create({:taxonomy => @ty, :name => 't_c0', :parent => @t_b2, :position => 0})
    @t_c1 = Taxon.create({:taxonomy => @ty, :name => 't_c1', :parent => @t_b2, :position => 1})
    @t_c2 = Taxon.create({:taxonomy => @ty, :name => 't_c2', :parent => @t_b2, :position => 2})    

  end

  it "should not be valid when empty" do
    pending "Can it really be valid when empty?"
    @taxon.should_not be_valid
  end

  ['name'].each do |field|
    it "should require #{field}" do
      pending "Is this field mandatory?"
      @taxon.should_not be_valid
      @taxon.errors.full_messages.should include("#{field.intern.l(field).humanize} #{:error_message_blank.l}")
    end
  end
  
  it "should be valid when having correct information" do
    @taxon.attributes = valid_taxon_attributes

    @taxon.should be_valid
  end
  
  it "should set the permalink on create" do
    @taxon = Taxon.create(:name => "foo", :taxonomy => @taxonomy)
    @taxon.permalink.should == "foo/"
  end
  
  it "should update the permalink on update" do
    @taxon = Taxon.create(:name => "foo", :taxonomy => @taxonomy)
    @taxon.update_attribute("name", "fooz")
    @taxon.permalink.should == "fooz/"
  end
  
  it "should update permalinks when parent changes" do
    @t_c2.move_to!(@t_a0,0)
    @t_c2.permalink.should == "t_root/t_a0/t_c2/"
  end
  
  it "should update child taxon permalink when node moves" do
    @t_b2.move_to!(@t_root,1)
    # note be careful here, reference is stale
    @t_c2.reload
    @t_c2.permalink.should == "t_root/t_b2/t_c2/"
  end

  it "should not allow assigning a product group to a non leaf taxon" do
    pg = ProductGroup.new(:name => 'Test', :group_type => :product_group_list)

    @t_b2.product_group = pg
    @t_b2.should_not be_valid
  end

  it "should not allow assigning a child node to a taxon with a product group" do
    pg = ProductGroup.new(:name => 'Test', :group_type => :product_group_list)

    @t_a3.product_group = pg
    @t_a3.should be_valid
    
    begin
      @t_c2.move_to!(@t_a3, 0)
    rescue Exception => e
      @t_c2.should_not be_valid
    end
   
  end
end
