class CreateCustomers  < ActiveRecord::Migration[6.0]
  def self.up
    if ActiveRecord::Base.connection.table_exists? 'customers'
      drop_table :customers
    end
    create_table :customers do |t|
      t.string :customer_name
      t.string :phone
      t.string :email
      t.boolean :active, default: true
      t.datetime :created_on
      t.datetime :updated_on
    end
  end
  
  def self.down
      drop_table :customers
  end
end
