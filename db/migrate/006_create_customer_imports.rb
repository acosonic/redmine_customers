class CreateCustomerImports < ActiveRecord::Migration[6.0]
  def change
    create_table :customer_imports do |t|
      t.string :url
      t.text :settings
    end
  end
end
