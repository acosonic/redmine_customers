class IssuesHook < Redmine::Hook::ViewListener
  include ActionView::Helpers::TagHelper

  render_on :view_issues_context_menu_start,
            :partial => 'redmine_helpdesk_mns/view_issues_context_menu_start'

end
