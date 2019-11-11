class CreateCustomerImports < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :customer_imports do |t|
      t.string :url
      t.text :settings
    end
  end
end
