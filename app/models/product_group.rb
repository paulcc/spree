class ProductGroup < ActiveRecord::Base
  belongs_to :group, :polymorphic => true
  has_many :taxons

  include ProductSet

  def products
    group.products
  end

end

