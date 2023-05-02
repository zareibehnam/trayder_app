class CreateSunscribers < ActiveRecord::Migration[6.1]
  def change
    create_table :sunscribers do |t|
      t.string :name
      t.string :status
      t.string :address
      t.date :birthday
      t.string :socials
      t.string :phone_number
      t.timestamps
    end
  end
end
