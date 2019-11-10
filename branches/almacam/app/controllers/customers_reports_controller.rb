#
# Redmine 2.4 plugin - customers plugin
#
# Custom developed 2015,2016 for customers Mauritius
# Author: Aleksandar Pavic - acosonic@gmail.com
# LCP Services, Bul. P. Pavla 8/24, 21000 Novi Sad, Serbia
#
# Copyrighted by LCP and customers, built specifically to be used
# by customers for their existing Redmine instance
# Otherwise licensed as GPL (keep the copyright notice)
#
require 'wicked_pdf'
require 'date'

class CustomersReportsController < ApplicationController
  unloadable


  def index
  end

  def generate

    parsed_end_date = DateTime.strptime(params[:end_date], '%Y-%m-%d')
    params[:end_date] = parsed_end_date.next_day(1).strftime('%Y-%m-%d')
    
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    Rails.logger.info "Report parameter end_date increased by 1 to fit sql timestampdiff: " + @end_date

    # find SLA value
    sla_field_id = ProjectCustomField.find_by_name("SLA")
	if(sla_field_id.blank? )
	  render_error :status => 412, :message => "Project does not have custom field SLA value entered!"
      return false
    end
	
    @sla = CustomValue.where(:custom_field_id => sla_field_id.id,:customized_id => params[:project_id])
    if(@sla.blank? )
      render_error :status => 412, :message => "Project does not have custom field SLA value entered!"
      return false
    end
        
    #First table values
    @total      = runParameterQuery("select count(*) as value from issues where 1")
    
    if(@total.first["value"]==0)
        render_error :status => 404, :message => "There are no results! Please choose different dates!"
        return false
      end
       
    @value_15m  = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(MINUTE, created_on, closed_on)<=15");
    @value_4h   = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(MINUTE, created_on, closed_on)>15 and TIMESTAMPDIFF(MINUTE, created_on, closed_on)<=240")
    @value_4h1d = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(MINUTE, created_on, closed_on)>240 and TIMESTAMPDIFF(MINUTE, created_on, closed_on)<=1440");   
    @value_2d   = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(MINUTE, created_on, closed_on)>1440 and TIMESTAMPDIFF(MINUTE, created_on, closed_on)<=2880 ");
    @value_3d   = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(MINUTE, created_on, closed_on)>2880 and TIMESTAMPDIFF(DAY, created_on, closed_on)<=13");    
    @value_13d  = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(DAY, created_on, closed_on)>13");
    @value_sp   = runParameterQuery("select count(*) as value from issues where closed_on is NULL")
    
    #Second table values
    @urgent         = runParameterQuery("select count(*) as value from issues where priority_id=4")
    @high           = runParameterQuery("select count(*) as value from issues where priority_id=43")
    @immediate      = runParameterQuery("select count(*) as value from issues where priority_id=5")
    @medium         = runParameterQuery("select count(*) as value from issues where priority_id=3")
    @low            = runParameterQuery("select count(*) as value from issues where priority_id=1")
    @normal         = runParameterQuery("select count(*) as value from issues where priority_id=2")
    
    @project_name = runQuery("select name from projects where id="+params[:project_id])
    
    # Calculating the % within SLA
    sla_mins = @sla.first["value"]
    sla_mins = sla_mins.to_f * 60
    #Rails.logger.info "sla_mins" + sla_mins.to_s
    total_count = @total.first["value"].to_f
    sla_4h   = runParameterQuery("select count(*) as value from issues where TIMESTAMPDIFF(MINUTE, created_on, closed_on)<=" + sla_mins.to_s)
    sla_4h = sla_4h.first["value"].to_f
    #Rails.logger.info "sla_4h" + sla_4h.to_s
    @within_sla   = (sla_4h / total_count) * 100
    
    # Calculating categories breakdown
    Rails.logger.info "total" + total_count.to_s
    Rails.logger.info "\n\n" + "select count(*) as number,ROUND(((count(*)/"+total_count.to_s+")*100),2) as value, b.name from issues a left join issue_categories b on a.category_id=b.id where a.project_id="+params[:project_id]+" and a.created_on >= '"+@start_date+"' and a.created_on <= '"+@end_date+"' group by a.category_id"
    ptbreakdown = runQuery("select count(*) as number, ROUND(((count(*)/"+total_count.to_s+")*100),2) as value, b.name from issues a left join issue_categories b on a.category_id=b.id where a.project_id="+params[:project_id]+" and a.created_on >= '"+@start_date+"' and a.created_on <= '"+@end_date+"' group by a.category_id order by value")
    @pt = ptbreakdown
    respond_to do |format|
      format.html
      format.pdf do
        send_data(WickedPdf.new.pdf_from_string(render_to_string('customers_reports/generate', layout: 'layouts/wicked_pdf'), zoom: 0.5))
      end
      format.xls
      format.xlsx do
        send_file customersExcelGenerator.new(view_context: view_context).file
      end
    end
    
  end
  
  private
    
    def runParameterQuery(sql)
      start_date  = params[:start_date]
      end_date    = params[:end_date]
      project_id  = params[:project_id]
      result = ActiveRecord::Base.connection.exec_query(sql + " and created_on > '" + start_date + "' and created_on < '"+ end_date + "' and project_id="+project_id )
      return result.to_hash
    end
    
    def runQuery(sql)
      result = ActiveRecord::Base.connection.exec_query(sql)
      return result.to_hash
    end
end