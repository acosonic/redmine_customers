class ChangeContactId < ActiveRecord::Migration[6.0]
  def self.up
    change_column :customers, :contact_id, :string
  end

  def self.down
    change_column :customers, :contact_id, :integer
  end
end