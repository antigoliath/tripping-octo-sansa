class Expense < ActiveRecord::Base
  attr_accessible :cost, :exists, :location, :name, :owner_id
end
