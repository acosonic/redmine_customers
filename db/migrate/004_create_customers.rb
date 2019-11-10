class CreateCustomers  < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
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
