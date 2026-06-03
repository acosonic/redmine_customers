# Rails 7 / Redmine 6 port: 2026-06 (Inctime)
# Adds a "Customer" tab to the admin Custom Fields page.
module RedmineCustomers
  module CustomFieldsHelperPatch
    def self.apply!
      require_dependency 'custom_fields_helper'
      tabs = CustomFieldsHelper::CUSTOM_FIELDS_TABS
      return if tabs.any? { |t| t[:name] == 'CustomerCustomField' }

      tabs << {
        name:    'CustomerCustomField',
        partial: 'custom_fields/index',
        label:   :label_customer_plural
      }
    end
  end
end
