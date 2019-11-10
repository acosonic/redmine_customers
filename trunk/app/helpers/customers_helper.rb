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
module CustomersHelper
  def edit_link(url, options={})
    options = {
      :method => :delete,
      :data => {:confirm => l(:text_are_you_sure)},
      :class => 'icon icon-edit'
    }.merge(options)

    link_to l(:button_edit), url, options
  end


  def customer_list(customers, &block)
    ancestors = []
    customers.each do |customer|
      while ancestors.any?
        ancestors.pop
      end
      yield customer, ancestors.size
      ancestors << customer
    end
  end

  def grouped_customer_list(customers, query, &block)
    ancestors = []
    grouped_query_results(customers, query) do |customer, group_name, group_count, group_totals|
      while ancestors.any?
        ancestors.pop
      end
      yield customer, ancestors.size, group_name, group_count, group_totals
      ancestors << customer
    end
  end

  def customer_column_content(column, item)
    value = column.value_object(item)
    if value.is_a?(Array)
      values = value.collect {|v| column_value(column, item, v)}.compact
      safe_join(values, ', ')
    else
      customer_column_value(column, item, value)
    end
  end

  def customer_render_half_width_custom_fields_rows(customer)
    values = customer.custom_field_values
    return if values.empty?
    half = (values.size / 2.0).ceil
    issue_fields_rows do |rows|
      values.each_with_index do |value, i|
        css = "cf_#{value.custom_field.id}"
        m = (i < half ? :left : :right)
        rows.send m, custom_field_name_tag(value.custom_field), show_value(value), :class => css
      end
    end
  end


  def customer_column_value(column, item, value)
    case column.name
      when :id
        link_to value, customer_path(item)
      else
        format_object(value)
    end
  end

end
