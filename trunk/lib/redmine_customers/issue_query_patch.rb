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
  module IssueQueryPatch
    def self.included(base)
      base.class_eval do
        unloadable

        self.available_columns <<  QueryColumn.new(:customer_name, :sortable => "#{Customer.table_name}.name", :groupable => true)
        self.available_columns <<  QueryColumn.new(:phone, :sortable => "#{Customer.table_name}.phone", :groupable => true)
        self.available_columns <<  QueryColumn.new(:email, :sortable => "#{Customer.table_name}.email", :groupable => true)


        alias_method :initialize_available_filters_original, :initialize_available_filters

        def initialize_available_filters
          self.available_columns += CustomerCustomField.where(nil).visible.collect {|cf| QueryCustomFieldColumn.new(cf) }
          if User.current.admin?
            add_available_filter "name", :type => :text
            add_available_filter "phone", :type => :text
            add_available_filter "email", :type => :text


            add_custom_fields_filters(CustomerCustomField.all, assoc=nil)


          end
          initialize_available_filters_original
        end


        def sql_for_custom_field(field, operator, value, custom_field_id)
          db_table = CustomValue.table_name
          db_field = 'value'
          filter = @available_filters[field]
          return nil unless filter
          if filter[:field].format.target_class && filter[:field].format.target_class <= User
            if value.delete('me')
              value.push User.current.id.to_s
            end
          end
          not_in = nil
          if operator == '!'
            # Makes ! operator work for custom fields with multiple values
            operator = '='
            not_in = 'NOT'
          end
          customized_key = "id"
          customized_class = queried_class
          if field =~ /^(.+)\.cf_/
            assoc = $1
            customized_key = "#{assoc}_id"
            customized_class = queried_class.reflect_on_association(assoc.to_sym).klass.base_class rescue nil
            raise "Unknown #{queried_class.name} association #{assoc}" unless customized_class
          end
          where = sql_for_field(field, operator, value, db_table, db_field, true)
          if operator =~ /[<>]/
            where = "(#{where}) AND #{db_table}.#{db_field} <> ''"
          end
          if CustomField.find_by_id(custom_field_id).is_a? CustomerCustomField
            "#{queried_table_name}.#{customized_key} #{not_in} IN ( #{Issue.joins(:customer).where(customers: {active: true}).select('issues.id').to_sql}  " +
                " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Customer' AND #{db_table}.customized_id=#{Customer.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id}" +
                " WHERE (#{where}) AND (#{filter[:field].visibility_by_project_condition}))"
          else
            "#{queried_table_name}.#{customized_key} #{not_in} IN (" +
                "SELECT #{customized_class.table_name}.id FROM #{customized_class.table_name}" +
                " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='#{customized_class}' AND #{db_table}.customized_id=#{customized_class.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id}" +
                " WHERE (#{where}) AND (#{filter[:field].visibility_by_project_condition}))"
          end

        end


        CustomerCustomField.all.each do |customer_custom_field|
          field_name = customer_custom_field.name
          define_method("sql_for_#{field_name}_field") do |field, operator, value|
            db_table = Customer.table_name
            "#{Issue.table_name}.id IN (#{Issue.joins(:customer).select('issues.id').to_sql} AND #{sql_for_customer_custom_field(field, operator, value, customer_custom_field.id)})"
          end
        end

        %w(customer_name phone email).each do |field_name|
          define_method("sql_for_#{field_name}_field") do |field, operator, value|
            db_table = Customer.table_name
            "#{Issue.table_name}.id IN (#{Issue.joins(:customer).select('issues.id').to_sql} AND #{sql_for_field(field, operator, value, db_table, field)})"
          end
        end

      end
    end
  end
end

unless IssueQuery.included_modules.include?(RedmineCustomers::IssueQueryPatch)
  IssueQuery.send(:include, RedmineCustomers::IssueQueryPatch)
end
