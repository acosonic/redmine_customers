require_dependency 'custom_fields_helper'

module RedmineCustomers
  module Patches

    module CustomFieldsHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :custom_fields_tabs, :customers_tab
        end
      end

      module InstanceMethods
        def custom_fields_tabs_with_customers_tab
          new_tabs = []
          new_tabs << {:name => 'ContactCustomField', :partial => 'custom_fields/index', :label => :label_customer_plural}
          return custom_fields_tabs_without_customers_tab | new_tabs
        end
      end

    end

  end
end

if Redmine::VERSION.to_s > '2.5'
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => 'CustomerCustomField', :partial => 'custom_fields/index', :label => :label_customer_plural}
else
  unless CustomFieldsHelper.included_modules.include?(RedmineCustomers::Patches::CustomFieldsHelperPatch)
    CustomFieldsHelper.send(:include, RedmineCustomers::Patches::CustomFieldsHelperPatch)
  end
end
