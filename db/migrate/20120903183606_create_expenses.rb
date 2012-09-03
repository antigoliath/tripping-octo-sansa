class CreateExpenses < ActiveRecord::Migration
  def change
    create_table :expenses do |t|
      t.boolean :exists
      t.string :location
      t.string :name
      t.decimal :cost
      t.integer :owner_id

      t.timestamps
    end
  end
end
