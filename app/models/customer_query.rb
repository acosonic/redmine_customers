class CustomerQuery < Query

  self.queried_class = Customer
  self.view_permission = :view_customers

  self.available_columns = [
      QueryColumn.new(:id, :sortable => "#{Customer.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
      QueryColumn.new(:customer_name, :sortable => "#{Customer.table_name}.customer_name", :default_order => 'desc', :frozen => true),
      QueryColumn.new(:phone, :sortable => "#{Customer.table_name}.phone", :default_order => 'desc'),
      QueryColumn.new(:email, :sortable => "#{Customer.table_name}.email", :default_order => 'desc'),
      QueryColumn.new(:contact_id, :sortable => "#{Customer.table_name}.contact_id", :default_order => 'desc'),
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { '' => {:operator => "o", :values => []} }
  end

  def draw_relations
    r = options[:draw_relations]
    r.nil? || r == '1'
  end

  def draw_relations=(arg)
    options[:draw_relations] = (arg == '0' ? '0' : nil)
  end

  def draw_progress_line
    r = options[:draw_progress_line]
    r == '1'
  end

  def draw_progress_line=(arg)
    options[:draw_progress_line] = (arg == '1' ? '1' : nil)
  end

  if Redmine::VERSION::MAJOR >= 4
    def build_from_params(params, default= {})
      super
      self.draw_relations = params[:draw_relations] || (params[:query] && params[:query][:draw_relations])
      self.draw_progress_line = params[:draw_progress_line] || (params[:query] && params[:query][:draw_progress_line])
      self
    end
  else
    def build_from_params(params)
      super
      self.draw_relations = params[:draw_relations] || (params[:query] && params[:query][:draw_relations])
      self.draw_progress_line = params[:draw_progress_line] || (params[:query] && params[:query][:draw_progress_line])
      self
    end
  end


  def initialize_available_filters

    add_available_filter "customer_name", :type => :text
    add_available_filter "email", :type => :text
    add_available_filter "phone", :type => :text
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past

    add_custom_fields_filters( customer_custom_fields)

  end

  def customer_custom_fields
    CustomerCustomField.all
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += customer_custom_fields.visible.collect {|cf| QueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= begin
      default_columns = Setting.issue_list_default_columns.map(&:to_sym)

      project.present? ? default_columns : [:project] | default_columns
    end
  end

  def default_totalable_names
    Setting.issue_list_default_totals.map(&:to_sym)
  end

  def default_sort_criteria
    [['id', 'desc']]
  end

  def base_scope
    Customer.visible.where(statement)
  end

  # Returns the issue count
  def customer_count
    base_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the issues
  # Valid options are :order, :offset, :limit, :include, :conditions
  def customers(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = Customer.visible.
        where(statement).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end
    customers = scope.to_a

    customers
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the issues ids
  def customers_ids(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    Customer.visible.
        limit(options[:limit]).
        offset(options[:offset]).
        pluck(:id)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end




  def sql_for_updated_on_field(field, operator, value)
    case operator
      when "!*"
        "#{Customer.table_name}.updated_on = #{Customer.table_name}.created_on"
      when "*"
        "#{Customer.table_name}.updated_on > #{Customer.table_name}.created_on"
      else
        sql_for_field("updated_on", operator, value, Customer.table_name, "updated_on")
    end
  end

  def sql_for_customer_id_field(field, operator, value)
    if operator == "="
      # accepts a comma separated list of ids
      ids = value.first.to_s.scan(/\d+/).map(&:to_i)
      if ids.present?
        "#{Customer.table_name}.id IN (#{ids.join(",")})"
      else
        "1=0"
      end
    else
      sql_for_field("id", operator, value, Customer.table_name, "id")
    end
  end

  %w(customer_name phone email).each do |field_name|
    define_method("sql_for_#{field_name}_field") do |field, operator, value|
      db_table = Customer.table_name
      "#{sql_for_field(field, operator, value, db_table, field)}"
    end
  end


  def joins_for_order_statement(order_options)
    joins = [super]

    joins.any? ? joins.join(' ') : nil
  end
end
