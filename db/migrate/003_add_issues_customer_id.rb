# Extends standard Issues table with customer_id
class AddIssuesCustomerId < ActiveRecord::Migration[6.0]
  def self.up
    add_column :issues, :customer_id, :integer
  end

  def self.down
    remove_column :issues, :customer_id
  end
end