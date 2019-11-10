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
class CustomersIssuesHookListener < Redmine::Hook::ViewListener
  include ActionView::Helpers::TagHelper
  render_on :view_custom_fields_form_customer_custom_field,   :partial => 'custom_fields/customer_custom_field'

  def view_issues_form_details_top(context={})
    #Rails.logger.info "Successful load of customers issue hook form details"
    issue = context[:issue]
    if issue && issue.project
      context[:hook_caller].send(:render, :partial => "issues/choose_issue_system", :locals => context)
    end
  end

  def view_issues_new_top(context={})
    #Rails.logger.info "Successful load of customers issue hook title"
    if context[:project]
      if context[:hook_caller].respond_to?(:render) and context[:request].parameters[:id].blank? and (context[:controller].action_name == "new" or context[:controller].action_name == "update_form")
        context[:hook_caller].send(:render, :partial => "issues/new_issue_top", :locals => context)
      elsif context[:controller].is_a?(ActionController::Base) and context[:request].parameters[:id].blank? and (context[:controller].action_name == "new" or context[:controller].action_name == "update_form")
        context[:controller].send(:render_to_string, :partial => "issues/new_issue_top", :locals => context)
      else
        ""
      end
    end
  end

  def view_issues_show_details_bottom(context={})
    #Rails.logger.info "Successful load of customers view issue hook"
    if context[:project]
      context[:hook_caller].send(:render, :partial => "issues/show_details", :locals => context)
    end
  end


  def view_layouts_base_html_head(context={})
    #Rails.logger.info "Successful load of customers base layout hook"
    stylesheet_link_tag(:application, :plugin => 'customers')
  end

end
