# Rails 7 port: 2026-06 (Inctime)
module RedmineCustomers
  module ContextMenusControllerPatch
    def customers
      @customers = Customer.where(id: params[:ids])
      @customer = @customers.first if @customers.size == 1
      @customer_ids = @customers.pluck(:id).sort

      @can = {
        edit:   @customers.all?(&:attributes_editable?),
        delete: @customers.all?(&:deletable?)
      }

      @back = back_url

      @options_by_custom_field = {}
      if @can[:edit]
        custom_fields = @customers.map(&:editable_custom_fields).reduce(:&)
                                  .reject(&:multiple?)
                                  .select { |field| field.format.bulk_edit_supported }
        custom_fields.each do |field|
          values = field.possible_values_options(@projects)
          @options_by_custom_field[field] = values if values.present?
        end
      end

      @safe_attributes = @customers.map(&:safe_attribute_names).reduce(:&)
      render layout: false
    end
  end
end
