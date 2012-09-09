class AddGoogleIdToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :google_doc_id, :string
    add_column :expenses, :expire_time, :datetime
  end
end
