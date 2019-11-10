# Extends standard Issues table with customer_id
class AddIssuesCustomerId < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :customer_id, :integer
  end

  def self.down
    remove_column :issues, :customer_id
  end
end