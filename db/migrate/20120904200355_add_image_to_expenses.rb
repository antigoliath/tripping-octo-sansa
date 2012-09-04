class AddImageToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :image, :string
  end
end
