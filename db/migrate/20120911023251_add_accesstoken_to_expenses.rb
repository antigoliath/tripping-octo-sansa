class AddAccesstokenToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :access_token, :string
  end
end
