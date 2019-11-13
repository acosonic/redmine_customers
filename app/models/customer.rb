#
# Redmine 2.4 plugin - customers plugin
#
# Custom developed 2016,2017 for customers Mauritius
# Author: Aleksandar Pavic - acosonic@gmail.com
# LCP Services, Bul. P. Pavla 8/24, 21000 Novi Sad, Serbia
#
# Copyrighted by LCP and customers, built specifically to be used
# by customers for their existing Redmine instance
# Otherwise licensed as GPL (keep the copyright notice)
#
class Customer < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  include Redmine::I18n

  validates_uniqueness_of :contact_id, :allow_blank => true

  safe_attributes 'customer_name',      'phone',      'email',  'custom_field_values', 'contact_id'

  has_many :issues
  acts_as_searchable :columns => ["#{Customer.table_name}.customer_name", "#{Customer.table_name}.phone","#{Customer.table_name}.contact_id",
                                  "#{Customer.table_name}.email"],
                    :preload => {:issues => :project},
                    :project_key => "#{Issue.table_name}.project_id"


  acts_as_event :title => Proc.new {|o| "#{o.customer_name}"},
                description: :description,
                :url => Proc.new {|o| {:controller => 'customers', :action => 'show', :id => o.id}},
                :type => Proc.new {|o| 'customer' },
                :datetime => :created_at

  acts_as_customizable

  def self.visible(user = User.current)
    where(active: true)
  end

  def self.customer_attrs
    attrs = []
    attrs<< Customer.column_names
    attrs<< CustomerCustomField.pluck(:name)
    attrs.flatten.compact
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
    where("customer_name LIKE ?", "%#{search}%")
  end

  def event_datetime
    created_on
  end

  # Returns the custom_field_values that can be edited by the given user
  def editable_custom_field_values(user=nil)
    visible_custom_field_values(user)
  end

  def visible_custom_field_values(user=nil)
    custom_field_values
  end

  def project
    nil
  end

  # Returns the custom fields that can be edited by the given user
  def editable_custom_fields(user=nil)
    editable_custom_field_values(user).map(&:custom_field).uniq
  end


  ##
  # Custom serializer
  
  def to_s
    customer_name + email + phone
  end
end
