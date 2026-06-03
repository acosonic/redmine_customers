class AddGroupToCustomer < ActiveRecord::Migration[6.0]
  def change
    add_column :customers, :group_id, :integer
  end
end