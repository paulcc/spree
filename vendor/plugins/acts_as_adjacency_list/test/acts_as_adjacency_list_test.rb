require 'test/unit'

require 'rubygems'

require 'active_record'
require 'set'

$:.unshift File.dirname(__FILE__) + '/../lib'
require File.dirname(__FILE__) + '/../init'

class Test::Unit::TestCase
  def assert_queries(num = 1)
    $query_count = 0
    yield
  ensure
    assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

# AR keeps printing annoying schema statements
 $stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :type, :string
      t.column :parent_id, :integer
      t.column :position, :integer
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class AdjacencyListMixin < Mixin 
  acts_as_adjacency_list :foreign_key => "parent_id", :order => "position"
end

class AdjacencyListMixinWithoutOrder < Mixin
  acts_as_adjacency_list :foreign_key => "parent_id"
end

class RecursivelyCascadedAdjacencyListMixin < Mixin
  acts_as_adjacency_list :foreign_key => "parent_id"
  has_one :first_child, :class_name => 'RecursivelyCascadedAdjacencyListMixin', :foreign_key => :parent_id
end

class AdjacencyListTest < Test::Unit::TestCase
  
  def setup
    setup_db
    @root1 = AdjacencyListMixin.create!
    @root_child1 = AdjacencyListMixin.create! :parent_id => @root1.id
    @child1_child = AdjacencyListMixin.create! :parent_id => @root_child1.id
    @root_child2 = AdjacencyListMixin.create! :parent_id => @root1.id
    @root2 = AdjacencyListMixin.create!
    @root3 = AdjacencyListMixin.create!

    @root1.reload
    @root_child1.reload
    @root_child2.reload
    @child1_child.reload
  end

  def teardown
    teardown_db
  end

  def test_ordered
    assert AdjacencyListMixin.ordered?
    assert_equal AdjacencyListMixin.ordered, 'position'
  end

  def test_before_create_with_position
    node = AdjacencyListMixin.create!(:position => 3)
    assert node.valid?
    assert_equal node.position, 3
  end
  
  def test_before_create_wo_position
    node = AdjacencyListMixin.create!(:position => nil)
    assert node.valid?
    assert_equal node.position, 0
  end
  
  def test_before_create_wo_position_with_parent
    l = @root1.children.length
    node = AdjacencyListMixin.create!(:parent => @root1, :position => nil)
    assert node.valid?
    assert_equal node.position, l
  end
  
  def test_children_first
    assert_equal @root1.children, [@root_child1, @root_child2]
    assert_equal @root_child1.children, [@child1_child]
    assert_equal @child1_child.children, []
    assert_equal @root_child2.children, []
  end

  def test_parent
    assert_equal @root_child1.parent, @root1
    assert_equal @root_child1.parent, @root_child2.parent
    assert_nil @root1.parent
  end

  def test_delete
    assert_equal 6, AdjacencyListMixin.count
    @root1.destroy
    assert_equal 2, AdjacencyListMixin.count
    @root2.destroy
    @root3.destroy
    assert_equal 0, AdjacencyListMixin.count
  end

  def test_insert
    @extra = @root1.children.create

    assert @extra

    assert_equal @extra.parent, @root1

    assert_equal 3, @root1.children.size
    assert @root1.children.include?(@extra)
    assert @root1.children.include?(@root_child1)
    assert @root1.children.include?(@root_child2)
  end

  def test_ancestors
    assert_equal [], @root1.ancestors
    assert_equal [@root1], @root_child1.ancestors
    assert_equal [@root_child1, @root1], @child1_child.ancestors
    assert_equal [@root1], @root_child2.ancestors
    assert_equal [], @root2.ancestors
    assert_equal [], @root3.ancestors
  end

  def test_root
    assert_equal @root1, AdjacencyListMixin.root
    assert_equal @root1, @root1.root
    assert_equal @root1, @root_child1.root
    assert_equal @root1, @child1_child.root
    assert_equal @root1, @root_child2.root
    assert_equal @root2, @root2.root
    assert_equal @root3, @root3.root
  end

  def test_roots
    assert AdjacencyListMixin.roots.include? @root1
    assert AdjacencyListMixin.roots.include? @root2
    assert AdjacencyListMixin.roots.include? @root3
  end

  def test_children_second
    root = AdjacencyListMixin.create!(:position => 0)
    a0 = AdjacencyListMixin.create!({:parent => root, :position => 0})
    a1 = AdjacencyListMixin.create!({:parent => root, :position => 1})
    a2 = AdjacencyListMixin.create!({:parent => root, :position => 2})    
    a3 = AdjacencyListMixin.create!({:parent => root, :position => 3})

    assert_equal root, a0.parent
    root.reload
    assert_equal [a0, a1, a2, a3], root.children
  end

  def test_siblings
    assert_equal [@root_child2], @root_child1.siblings
    assert_equal [], @child1_child.siblings
    assert_equal [@root_child1], @root_child2.siblings
    assert ([@root2, @root3].to_set ^ @root1.siblings.to_set).empty?
    assert ([@root1, @root3].to_set ^ @root2.siblings.to_set).empty?
    assert ([@root1, @root2].to_set ^ @root3.siblings.to_set).empty?
  end

  def test_root_self_and_siblings
    s1 = [@root1, @root2, @root3].to_set
    s2 = @root1.self_and_siblings.to_set

    assert (s1 ^ s2).empty?
  end
  
  def test_ordered_self_and_siblings
    assert_equal [@root_child1, @root_child2], @root_child1.self_and_siblings
    assert_equal [@child1_child], @child1_child.self_and_siblings
    assert_equal [@root_child1, @root_child2], @root_child2.self_and_siblings
end


  def test_descendants
    assert_equal [@root_child1, @child1_child, @root_child2], @root1.descendents
    assert_equal [], @root2.descendents
    assert_equal [@child1_child], @root_child1.descendents
  end

  def test_root?
    assert @root1.root?
    assert !@root_child1.root?
  end

  def test_leaf?
    assert @root_child2.leaf?
    assert @child1_child.leaf?
    assert @root2.leaf?
    assert !@root1.leaf?
    assert !@root_child1.leaf?
  end

  def test_leaves
    assert_equal [@child1_child, @root_child2], @root1.leaves
    assert_equal [@child1_child], @root_child1.leaves
    assert_equal [@root2], @root2.leaves
  end

  def test_prune
    @child1_child.prune
    assert @root_child1.leaf?
    assert_equal [@root_child1, @root_child2], @root1.descendents
    teardown
    
    setup
    @root_child1.prune
    assert_equal [@root_child2], @root1.children
    teardown

    setup
    @root1.prune
    assert_equal [@root2], @root3.siblings
  end

  def test_prune_back
    @child1_child.prune_back
    assert_equal [@root_child2], @root1.children
    teardown
    
    setup
    @root_child1.prune_back
    assert_equal [@root_child2], @root1.children
  end

  def test_insert_at!
    node0 = AdjacencyListMixin.create!
    node0.insert_at!(@root1)
    @root1.reload
    assert @root1.children.include?(node0)
    assert_equal [@root_child1, @root_child2, node0], @root1.children
  end

  def test_move_to!
    @child1_child.move_to!(@root3)
    @root3.reload
    @root_child1.reload
    
    assert_equal [@child1_child], @root3.children
    assert ! @root_child1.children.include?(@child1_child)
  end
  
  def test_move_to!_with_position
    root = AdjacencyListMixin.create!(:position => 0)
    a0 = AdjacencyListMixin.create!({:parent => root, :position => 0})
    a1 = AdjacencyListMixin.create!({:parent => root, :position => 1})
    a2 = AdjacencyListMixin.create!({:parent => root, :position => 2})    
    a3 = AdjacencyListMixin.create!({:parent => root, :position => 3})
    b1 = AdjacencyListMixin.create!({:parent => a3, :position => 0})

    root.reload
    a3.reload
    
    b1.move_to!(root,2)
    root.reload
    assert_equal [a0, a1, b1, a2, a3], root.children
  end
end

# class AdjacencyListTestWithEagerLoading < Test::Unit::TestCase
  
#   def setup 
#     teardown_db
#     setup_db
#     @root1 = AdjacencyListMixin.create!
#     @root_child1 = AdjacencyListMixin.create! :parent_id => @root1.id
#     @child1_child = AdjacencyListMixin.create! :parent_id => @root_child1.id
#     @root_child2 = AdjacencyListMixin.create! :parent_id => @root1.id
#     @root2 = AdjacencyListMixin.create!
#     @root3 = AdjacencyListMixin.create!
    
#     @rc1 = RecursivelyCascadedAdjacencyListMixin.create!
#     @rc2 = RecursivelyCascadedAdjacencyListMixin.create! :parent_id => @rc1.id 
#     @rc3 = RecursivelyCascadedAdjacencyListMixin.create! :parent_id => @rc2.id
#     @rc4 = RecursivelyCascadedAdjacencyListMixin.create! :parent_id => @rc3.id
#   end

#   def teardown
#     teardown_db
#   end
    
#   def test_eager_association_loading
#     roots = AdjacencyListMixin.find(:all, :include => :children, :conditions => "mixins.parent_id IS NULL", :order => "mixins.id")
#     assert_equal [@root1, @root2, @root3], roots                     
#     assert_no_queries do
#       assert_equal 2, roots[0].children.size
#       assert_equal 0, roots[1].children.size
#       assert_equal 0, roots[2].children.size
#     end   
#   end
  
#   def test_eager_association_loading_with_recursive_cascading_three_levels_has_many
#     root_node = RecursivelyCascadedAdjacencyListMixin.find(:first, :include => { :children => { :children => :children } }, :order => 'mixins.id')
#     assert_equal @rc4, assert_no_queries { root_node.children.first.children.first.children.first }
#   end
  
#   def test_eager_association_loading_with_recursive_cascading_three_levels_has_one
#     root_node = RecursivelyCascadedAdjacencyListMixin.find(:first, :include => { :first_child => { :first_child => :first_child } }, :order => 'mixins.id')
#     assert_equal @rc4, assert_no_queries { root_node.first_child.first_child.first_child }
#   end
  
#   def test_eager_association_loading_with_recursive_cascading_three_levels_belongs_to
#     leaf_node = RecursivelyCascadedAdjacencyListMixin.find(:first, :include => { :parent => { :parent => :parent } }, :order => 'mixins.id DESC')
#     assert_equal @rc1, assert_no_queries { leaf_node.parent.parent.parent }
#   end 
# end

# class AdjacencyListTestWithoutOrder < Test::Unit::TestCase
  
#   def setup                               
#     setup_db
#     @root1 = AdjacencyListMixinWithoutOrder.create!
#     @root2 = AdjacencyListMixinWithoutOrder.create!
#   end

#   def teardown
#     teardown_db
#   end

#   def test_root
#     assert [@root1, @root2].include?(AdjacencyListMixinWithoutOrder.root)
#   end
  
#   def test_roots
#     assert_equal [], [@root1, @root2] - AdjacencyListMixinWithoutOrder.roots
#   end
# end 
