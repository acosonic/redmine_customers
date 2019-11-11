class CreateCustomerImports < ActiveRecord::Migration
  def change
    create_table :customer_imports do |t|
      t.string :url
      t.text :settings
    end
  end
end
