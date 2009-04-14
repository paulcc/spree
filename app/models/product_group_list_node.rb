class ProductGroupListNode < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_group_list
  acts_as_list :scope => :product_group_list_id
end
