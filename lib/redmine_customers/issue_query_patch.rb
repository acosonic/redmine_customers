# Custom developed 2016-2017 for customers Mauritius
# Author: Aleksandar Pavic - LCP Services
# Rails 7 / Redmine 6 port: 2026-06 (Inctime)
# GPL

module RedmineCustomers
  module IssueQueryPatch
    def self.prepended(base)
      base.class_eval do
        # idempotent column registration (prepend runs once but be defensive)
        new_cols = [
          QueryColumn.new(:customer_name, sortable: "customers.customer_name", groupable: true),
          QueryColumn.new(:phone,         sortable: "customers.phone",         groupable: true),
          QueryColumn.new(:email,         sortable: "customers.email",         groupable: true),
          QueryColumn.new(:group,         sortable: "customers.group",         groupable: true)
        ]
        existing_names = available_columns.map(&:name)
        new_cols.each { |col| available_columns << col unless existing_names.include?(col.name) }

        # Generate one sql_for_<name>_field method per CustomerCustomField.
        # NOTE: evaluated lazily on first IssueQuery instance — schema_loader
        # may not be ready at plugin boot time, so we guard the lookup.
        Rails.application.config.after_initialize do
          if defined?(CustomerCustomField) &&
             ActiveRecord::Base.connection.data_source_exists?('custom_fields')
            CustomerCustomField.all.each do |ccf|
              field_name = ccf.name
              ccf_id = ccf.id
              define_method("sql_for_#{field_name}_field") do |field, operator, value|
                "#{Issue.table_name}.id IN (#{Issue.joins(:customer).select('issues.id').to_sql} " \
                  "AND #{sql_for_customer_custom_field(field, operator, value, ccf_id)})"
              end
            end
          end
        end

        %w[customer_name phone email].each do |field_name|
          define_method("sql_for_#{field_name}_field") do |field, operator, value|
            db_table = Customer.table_name
            "#{Issue.table_name}.id IN (#{Issue.joins(:customer).select('issues.id').to_sql} " \
              "AND #{sql_for_field("customers.#{field}", operator, value, db_table, field)})"
          end
        end

        define_method(:sql_for_customer_group_id_field) do |field, operator, value|
          db_table = Customer.table_name
          "#{Issue.table_name}.id IN (#{Issue.joins(:customer).select('issues.id').to_sql} " \
            "AND #{sql_for_field('customers.group_id', operator, value, db_table, 'group_id')})"
        end
      end
    end

    def initialize_available_filters
      self.available_columns += CustomerCustomField.where(nil).visible.collect { |cf| QueryCustomFieldColumn.new(cf) }

      if User.current.allowed_to_globally?(:view_customers, {}) ||
         User.current.allowed_to_globally?(:manage_customers, {})
        add_available_filter 'customer_name',
                             type: :text
        add_available_filter 'customer_group_id',
                             type:   :list,
                             values: Group.active.pluck(:lastname, :id).collect { |name, id| [name, id.to_s] }
        add_available_filter 'phone', type: :text
        add_available_filter 'email', type: :text

        add_custom_fields_filters(CustomerCustomField.all)
      end

      super
    end

    def sql_for_custom_field(field, operator, value, custom_field_id)
      cf = CustomField.find_by(id: custom_field_id)
      return super unless cf.is_a?(CustomerCustomField)

      db_table = CustomValue.table_name
      db_field = 'value'
      filter = @available_filters[field]
      return nil unless filter

      if filter[:field].format.target_class && filter[:field].format.target_class <= User
        value.push(User.current.id.to_s) if value.delete('me')
      end

      not_in = nil
      if operator == '!'
        operator = '='
        not_in = 'NOT'
      end

      customized_key = 'id'
      customized_class = queried_class
      if field =~ /^(.+)\.cf_/
        assoc = ::Regexp.last_match(1)
        customized_key = "#{assoc}_id"
        customized_class = queried_class.reflect_on_association(assoc.to_sym).klass.base_class rescue nil
        raise "Unknown #{queried_class.name} association #{assoc}" unless customized_class
      end

      where = sql_for_field(field, operator, value, db_table, db_field, true)
      where = "(#{where}) AND #{db_table}.#{db_field} <> ''" if operator =~ /[<>]/

      "#{queried_table_name}.#{customized_key} #{not_in} IN (" \
        "#{Issue.joins(:customer).where(customers: { active: true })
                 .joins(" LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Customer' " \
                        "AND #{db_table}.customized_id=#{Customer.table_name}.id " \
                        "AND #{db_table}.custom_field_id=#{custom_field_id}")
                 .where("(#{where}) AND (#{filter[:field].visibility_by_project_condition})")
                 .select('issues.id').to_sql})"
    end

    def base_scope
      Issue.visible.joins(:status, :project)
           .includes(:customer).references(:customer)
           .where(statement)
    end

    def issues(options = {})
      order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

      scope = Issue.visible
                   .joins(:status, :project)
                   .includes(:customer)
                   .preload(:priority)
                   .where(statement)
                   .includes(([:status, :project] + (options[:include] || [])).uniq)
                   .where(options[:conditions])
                   .order(order_option)
                   .joins(joins_for_order_statement(order_option.join(',')))
                   .limit(options[:limit])
                   .offset(options[:offset])

      preload_assocs = [:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] &
                       columns.map(&:name)
      scope = scope.preload(preload_assocs)
      scope = scope.preload(:custom_values) if has_custom_field_column?

      issues = scope.to_a

      Issue.load_visible_spent_hours(issues)       if has_column?(:spent_hours)
      Issue.load_visible_total_spent_hours(issues) if has_column?(:total_spent_hours)
      Issue.load_visible_last_updated_by(issues)   if has_column?(:last_updated_by)
      Issue.load_visible_relations(issues)         if has_column?(:relations)
      Issue.load_visible_last_notes(issues)        if has_column?(:last_notes)

      issues
    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end
  end
end
