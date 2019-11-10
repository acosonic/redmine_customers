module RedmineCustomers
  module ContextMenusControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do

      end
    end

    module InstanceMethods
      def customers
        @customers = Customer.where(id: params[:ids])
        if (@customers.size == 1)
          @customer = @customers.first
        end
        @customer_ids = @customers.pluck(:id).sort


        @can = {:edit => @customers.all?(&:attributes_editable?),
                :delete => @customers.all?(&:deletable?)
        }

        @back = back_url

        @options_by_custom_field = {}
        if @can[:edit]
          custom_fields = @customers.map(&:editable_custom_fields).reduce(:&).reject(&:multiple?).select {|field| field.format.bulk_edit_supported}
          custom_fields.each do |field|
            values = field.possible_values_options(@projects)
            if values.present?
              @options_by_custom_field[field] = values
            end
          end
        end

        @safe_attributes = @customers.map(&:safe_attribute_names).reduce(:&)
        render :layout => false
      end
    end
  end
end
