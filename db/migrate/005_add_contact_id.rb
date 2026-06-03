class AddContactId < ActiveRecord::Migration[6.0]
  def self.up
    add_column :customers, :contact_id, :string
  end

  def self.down
    remove_column :customers, :contact_id
  end
end