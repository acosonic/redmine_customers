# Extends standard Issues table with customer_id
class AddContactId < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def self.up
    add_column :customers, :contact_id, :string
  end

  def self.down
    remove_column :customers, :contact_id
  end
end