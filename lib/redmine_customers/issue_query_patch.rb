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
      base.send :include, InstanceMethods
      base.class_eval do
        unloadable

        self.available_columns <<  QueryColumn.new(:customer_name, :sortable => "#{Customer.table_name}.customer_name", :groupable => true)
        self.available_columns <<  QueryColumn.new(:phone, :sortable => "#{Customer.table_name}.phone", :groupable => true)
        self.available_columns <<  QueryColumn.new(:email, :sortable => "#{Customer.table_name}.email", :groupable => true)


        alias_method :initialize_available_filters_original, :initialize_available_filters
        #
        alias_method :sql_for_custom_field_without_customers, :sql_for_custom_field
        alias_method  :sql_for_custom_field, :sql_for_custom_field_with_customers
        #
         alias_method :base_scope_without_customers, :base_scope
         alias_method  :base_scope, :base_scope_with_customers
        #
           alias_method :issues_without_customers, :issues
           alias_method  :issues, :issues_with_customers

        def initialize_available_filters
          self.available_columns += CustomerCustomField.where(nil).visible.collect {|cf| QueryCustomFieldColumn.new(cf) }
          if User.current.allowed_to_globally?(:view_customers, {}) ||  User.current.allowed_to_globally?(:manage_customers, {})
            add_available_filter "customer_name", :type => :text
            add_available_filter "phone", :type => :text
            add_available_filter "email", :type => :text


            add_custom_fields_filters(CustomerCustomField.all)
          end
          initialize_available_filters_original
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
            "#{Issue.table_name}.id IN (#{Issue.joins(:customer).select('issues.id').to_sql} AND #{sql_for_field("customers.#{field}", operator, value, db_table, field)})"
          end
        end

      end
    end


    module InstanceMethods

      def issues_with_customers(options={})
        order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

        scope = Issue.visible.
            joins(:status, :project).
            includes(:customer).
            preload(:priority).
            where(statement).
            includes(([:status, :project] + (options[:include] || [])).uniq).
            where(options[:conditions]).
            order(order_option).
            joins(joins_for_order_statement(order_option.join(','))).
            limit(options[:limit]).
            offset(options[:offset])

        scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))
        if has_custom_field_column?
          scope = scope.preload(:custom_values)
        end

        issues = scope.to_a

        if has_column?(:spent_hours)
          Issue.load_visible_spent_hours(issues)
        end
        if has_column?(:total_spent_hours)
          Issue.load_visible_total_spent_hours(issues)
        end
        if has_column?(:last_updated_by)
          Issue.load_visible_last_updated_by(issues)
        end
        if has_column?(:relations)
          Issue.load_visible_relations(issues)
        end
        if has_column?(:last_notes)
          Issue.load_visible_last_notes(issues)
        end
        issues
      rescue ::ActiveRecord::StatementInvalid => e
        raise StatementInvalid.new(e.message)
      end

      def base_scope_with_customers
        scope = Issue.visible.joins(:status, :project).includes(:customer).references(:customer).where(statement)
        scope
      end

      def sql_for_custom_field_with_customers(field, operator, value, custom_field_id)
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
          "#{queried_table_name}.#{customized_key} #{not_in} IN (#{Issue.joins(:customer).where(customers: {active: true}).
              joins( " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Customer' AND #{db_table}.customized_id=#{Customer.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id}")
          .where("(#{where}) AND (#{filter[:field].visibility_by_project_condition})")
          .select('issues.id').to_sql}  )"
        else
          sql_for_custom_field_without_customers(field, operator, value, custom_field_id)
        end
      end
    end
  end
end

