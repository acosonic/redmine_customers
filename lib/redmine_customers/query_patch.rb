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
module RedmineCustomers
  module QueryPatch
    unloadable

    def self.included(base)
      base.class_eval do
        alias_method_chain :available_filters, :customer_id
        base.add_available_column(QueryColumn.new(:customer_id))
      end
    end

    def available_filters_with_customer_id
      return @available_filters if @available_filters

      available_filters_without_customer_id

      if User.current.logged?  #mazbe check permission here
        @available_filters["customer_id"] = {
            :name => l('field_customer'),
            :type => :text,
            :values => [[l(:text_involved), "1"]],
            :order => 4  # places it next to the Assignee filter
        }
      end

      core_filters = available_filters_without_customer_id

      core_filters["customer_id"] = {
          :type => :text, :order => 17
      }

      @available_filters = core_filters
    end


    def initialize_available_filters_with_customer_id
      initialize_available_filters_without_customer_id
      @available_filters["customer_id"] = {
          :name => l('field_customer'),
          :type => :text,
          :values => [[l(:text_involved), "1"]],
          :order => 4  # places it next to the Assignee filter
      }
      add_available_filter "customer",    :name => l('field_customer'), :type => :text
    end

  end
end
