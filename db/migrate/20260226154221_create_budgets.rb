class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets, id: :uuid do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
