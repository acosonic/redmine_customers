# Rails 7 / Redmine 6 port: 2026-06 (Inctime)
# - find_by_* -> find_by(field: ...)
# - serialize :settings, coder: YAML
# - replaced shell wget/rm with Net::HTTP and File.delete (no shell injection)
require 'csv'
require 'net/http'
require 'uri'

class CustomerImport < ApplicationRecord
  serialize :settings, coder: YAML, type: Hash

  def self.fetch_all
    all.each do |customer_import|
      customer_import.fetch
      customer_import.sync
      customer_import.delete_file
    rescue StandardError => e
      Rails.logger.error("CustomerImport ##{customer_import.id} failed: #{e.message}")
    end
  end

  def fetch
    uri = URI.parse(url)
    File.open(csv_path, 'wb') do |f|
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(Net::HTTP::Get.new(uri)) { |res| res.read_body { |chunk| f.write(chunk) } }
      end
    end
  end

  def sync(csv = nil, options = nil)
    @csv = csv || csv_path
    @handle_count = 0
    @failed_count = 0
    @failed_rows  = {}
    quote_chars = %w[" | ~ ^ & *]
    encoding  = (options || settings)[:encoding]
    splitter  = (options || settings)[:splitter]
    attrs_map = (options || settings)[:attrs_map]

    begin
      CSV.foreach(@csv,
                  headers: true, encoding: encoding,
                  quote_char: quote_chars.shift, col_sep: splitter,
                  liberal_parsing: true) do |csv_row|
        row = csv_row.to_h.transform_keys { |k| k.to_s.gsub('"', '') }

        contact_id_key = attrs_map['contact_id'].to_s.gsub(/[^a-zA-Z 0-9]/, '').gsub(/\s/, '-')

        customer = nil
        customer = Customer.find_by(contact_id: row[contact_id_key]) if row[attrs_map['contact_id']].present?
        customer ||= Customer.find_by(contact_id: row[contact_id_key]) if row[contact_id_key].present?
        customer ||= Customer.find_by(email: row[attrs_map['email']])  if row[attrs_map['email']].present?
        customer ||= Customer.new

        customer.customer_name = row[attrs_map['customer_name']]
        customer.phone         = row[attrs_map['phone']]
        customer.email         = row[attrs_map['email']]
        customer.contact_id    = row[attrs_map['contact_id']]
        customer.group_id      = Group.find_by(lastname: row[attrs_map['group_id']])&.id

        customer.visible_custom_field_values.each do |cfv|
          mapped = attrs_map[cfv.custom_field.name]
          cfv.value = row[mapped] if mapped.present?
        end

        unless customer.save
          Rails.logger.info(customer.errors.full_messages)
          @failed_count += 1
          @failed_rows[@handle_count + 1] = row
        end

        @handle_count += 1
      end
    rescue CSV::MalformedCSVError
      quote_chars.empty? ? raise : retry
    end

    [@failed_rows, @failed_count, @handle_count]
  end

  def delete_file
    File.delete(csv_path) if File.exist?(csv_path)
  end

  private

  def csv_path
    Rails.root.join('csv.csv').to_s
  end
end
