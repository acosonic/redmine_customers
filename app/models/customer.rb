# Custom developed 2016-2017 for customers Mauritius
# Author: Aleksandar Pavic - LCP Services
# Rails 7 / Redmine 6 port: 2026-06 (Inctime)
# GPL
class Customer < ApplicationRecord
  include Redmine::SafeAttributes
  include Redmine::I18n

  validates_uniqueness_of :contact_id, allow_blank: true

  safe_attributes 'customer_name', 'phone', 'email',
                  'custom_field_values', 'contact_id', 'group_id'

  has_many :issues
  belongs_to :group, optional: true

  acts_as_searchable columns: [
                       "#{Customer.table_name}.customer_name",
                       "#{Customer.table_name}.phone",
                       "#{Customer.table_name}.contact_id",
                       "#{Customer.table_name}.email"
                     ],
                     scope:       Customer.includes(issues: [:project]),
                     preload:     { issues: :project },
                     project_key: "#{Issue.table_name}.project_id"

  acts_as_event title:       proc { |o| o.customer_name.to_s },
                description: :description,
                url:         proc { |o| { controller: 'customers', action: 'show', id: o.id } },
                type:        proc { |_o| 'customer' },
                datetime:    :created_on

  acts_as_customizable

  def self.visible(_user = User.current)
    where(active: true)
  end

  def self.customer_attrs
    (column_names + CustomerCustomField.pluck(:name)).compact
  end

  def mail
    email
  end

  def attributes_editable?
    true
  end

  def deletable?
    true
  end

  def description
    "Name: #{customer_name}, Email: #{email}, Phone: #{phone} "
  end

  def self.acf(search)
    where('customer_name LIKE ?', "%#{search}%")
  end

  def event_datetime
    created_on
  end

  def editable_custom_field_values(user = nil)
    visible_custom_field_values(user)
  end

  def visible_custom_field_values(_user = nil)
    custom_field_values
  end

  def project
    nil
  end

  def editable_custom_fields(user = nil)
    editable_custom_field_values(user).map(&:custom_field).uniq
  end

  def to_s
    "#{customer_name}#{email}#{phone}"
  end
end
