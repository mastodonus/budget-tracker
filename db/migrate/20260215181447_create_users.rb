class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :oauth_id
      t.string :email
      t.string :name
      t.string :picture

      t.timestamps
    end
  end
end
