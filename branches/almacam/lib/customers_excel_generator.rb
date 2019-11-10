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
class CustomersExcelGenerator
  attr_reader :view_context

  def initialize(view_context)
    @view_context = view_context[:view_context]
    @package = Axlsx::Package.new
    @filename = "#{get_instance('start_date')}-#{get_instance('end_date')}-#{Time.now.to_i}"
  end

  def file
    add_report_rows(add_worksheet)
    @package.serialize("tmp/#{@filename}.xlsx")
    "tmp/#{@filename}.xlsx"
  end

  private

  def add_report_rows(worksheet)
    worksheet.add_row issue_report_headers
    worksheet.add_row issue_report_values
    worksheet.add_row []
    worksheet.add_row []
    worksheet.add_row []
    worksheet.add_row ["CALL PRIORITY"]
    worksheet.add_row %w(Urgent High Immediate Medium Low Normal)
    worksheet.add_row call_priority_values
    worksheet.add_row []
    worksheet.add_row []
    worksheet.add_row []
    worksheet.add_row ["% within SLA: #{get_instance('within_sla').to_f.round} %"]
    worksheet.add_row []
    worksheet.add_row ["Problem type breakdown"]
    worksheet.add_row ["Problem name", "% occurence", "Count"]
    get_instance("pt").each do |key|
      key['name'] = "Others" if key['name'].to_s.empty?
      worksheet.add_row [key['name'], "#{key['value']}%", key['number']]
    end
  end

  def add_worksheet
    @worksheet ||= @package.workbook.add_worksheet(:name => "#{get_instance('start_date')}-#{get_instance('end_date')}")
  end

  def get_instance(name)
    view_context.controller.instance_variable_get("@#{name}")
  end

  def issue_report_headers
    [
      "", "Project", "Service", "SLA(hrs)", "Calls Received", "Solved at 1st attempt or within 15 mins",
      "Solved from 5 mins - 4 hours", "Solved from 4 hours to 1 day",
      "Solved in 2 days", "Solved in 3 -13 days",  "Solved in more then 13 days",
      "Still pending"
    ]
  end

  def issue_report_values
    [
      1, "Customer Tickets", get_instance("project_name").first["name"], get_instance("sla").first["value"],
      get_instance("total").first["value"], get_instance("value_15m").first["value"],
      get_instance("value_4h").first["value"], get_instance("value_4h1d").first["value"],
      get_instance("value_2d").first["value"], get_instance("value_3d").first["value"],
      get_instance("value_13d").first["value"], get_instance("value_sp").first["value"]
    ]
  end

  def call_priority_values
    [
      get_instance("urgent").first["value"], get_instance("high").first["value"],
      get_instance("immediate").first["value"], get_instance("medium").first["value"],
      get_instance("low").first["value"], get_instance("normal").first["value"]
    ]
  end

end
