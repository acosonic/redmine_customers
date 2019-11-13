# Extends standard Issues table with customer_id
class ChangeContactId < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def self.up
    change_column :customers, :contact_id, :string
  end

  def self.down
    change_column :customers, :contact_id, :integer
  end
end