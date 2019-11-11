class CustomerImport < ActiveRecord::Base
  serialize :settings
  attr_accessible :csv
  def self.fetch_all
    all.each do |customer_import|
      begin
        customer_import.fetch
        customer_import.sync
        customer_import.delete_file
      rescue
      end
    end
  end

  def fetch
    `wget -c #{self.url} -O csv.csv`
    @csv = File.join(Rails.root, 'csv.csv')
  end

  def sync
    @handle_count = 0
    @failed_count = 0
    @failed_rows = Hash.new
    quote_chars = %w(" | ~ ^ & *)
    encoding = self.settings[:encoding]
    splitter = self.settings[:splitter]
    attrs_map = self.settings[:attrs_map]

    begin
      CSV.foreach(@csv, {:headers=>true, :encoding=>encoding, :quote_char=> quote_chars.shift, :col_sep=>splitter, liberal_parsing: true}) do |csv_row|
        row = {}
        csv_row.to_h.each do |k, v|
          row[k.to_s.gsub("\"", '')] = v
        end
        contact_id = attrs_map["contact_id"].to_s.gsub(/[^a-zA-Z 0-9]/, '').gsub(/\s/,'-')
        customer = Customer.find_by_contact_id(row[contact_id] ) if row[contact_id].present?
        customer ||= Customer.find_by_email(row[attrs_map["email"]] )  if row[attrs_map["email"]].present?
        customer ||= Customer.new

        customer.customer_name = row[attrs_map["customer_name"] ]
        customer.phone = row[attrs_map["phone"] ]
        customer.email = row[attrs_map["email"] ]
        customer.contact_id = row[attrs_map["contact_id"] ]
        customer.visible_custom_field_values.each do |custom_field_value|
          custom_field_value.value = row[attrs_map[custom_field_value.custom_field.name] ] if attrs_map[custom_field_value.custom_field.name].present?

        end


        if (!customer.save(:validate => false)) then
          logger.info(customer.errors.full_messages)
          @failed_count += 1
          @failed_rows[@handle_count + 1] = row
        end

        @handle_count += 1
      end # do
    rescue CSV::MalformedCSVError
      quote_chars.empty? ? raise : retry
    end
  end

  def delete_file
    `rm #{@csv}`
  end
end
