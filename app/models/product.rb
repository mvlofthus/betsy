class Product < ApplicationRecord
  has_and_belongs_to_many :categories, :join_table => :categories_products_joins # added this for relation to work
  has_many :orderitems

  # Custom Method: Retire a product from being sold, which hides it from browsing
end
