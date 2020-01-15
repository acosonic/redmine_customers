# Extends standard Issues table with customer_id
class AddGroupToCustomer < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :customers, :group_id, :integer
  end
end