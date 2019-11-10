##
#  Redmine 2.4 plugin - customers plugin
#
#  Custom developed 2015,2016 for customers Mauritius
#  Author: Aleksandar Pavic - acosonic@gmail.com
#  LCP Services, Bul. P. Pavla 8/24, 21000 Novi Sad, Serbia
#
#  Copyrighted by LCP and customers, built specifically to be used
#  by customers for their existing Redmine instance
#  Otherwise licensed as GPL (keep the copyright notice)
#
##

  require "customers_issues_hook_listener"


Redmine::Plugin.register :redmine_customers do
  name 'Redmine Customers plugin'
  author 'Aleksandar Pavic'
  description 'Custom developed plugin for customers - Mauritius'
  version '1.0.0'
  url 'http://customers.mu'
  author_url 'http://redminecookbook.com'
  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :customers_case, { :controller=> 'issues', :action=>  'new', :project_id=>'ctcbris' }, :caption => 'New Case', :if => Proc.new { User.current.logged? && User.current.allowed_to?({:controller => 'customers', :action => 'index'}, nil, {:global => true})}
    menu.push :customers_report, { :controller=> 'customers_reports', :action=>  'index' }, :caption => 'Report', :if => Proc.new { User.current.logged? && User.current.allowed_to?({:controller => 'customers', :action => 'index'}, nil, {:global => true})}
    menu.push :customers_customers, { :controller=> 'customers', :action=>  'index' }, :caption => 'Customers', :if => Proc.new { User.current.logged? && User.current.allowed_to?({:controller => 'customers', :action => 'index'}, nil, {:global => true})}
  end
  Redmine::Search.available_search_types << 'customers'
  
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :customers_customers, { controller: 'customers', action: 'index', id: 'customers' }, caption: 'Customers'
  end
  
  permission :view_customers, :customers => :index
  permission :activate_customers, :customers => [:active, :inactive]
  permission :manage_customers, :customers => [:index, :show, :active, :inactive, :new, :create, :edit, :update, :destroy]
  permission :add_customers, :customers => [:new, :create]
  permission :create_helpdesk_request, :helpdesk => :new

  # project_module :issue_tracking do
  #   permission :helpdesk, :issues=> [:helpdesk, :update_helpdesk_form]
  # end

  project_module :customers do
    permission :helpdesk, :issues=> [:helpdesk]
  end
end

require 'redmine_customers/custom_fields_helper_patch'


  unless IssuesController.included_modules.include?(RedmineHelpdeskCustomers::Patches::IssuesControllerPatch)
    IssuesController.send(:include, RedmineHelpdeskCustomers::Patches::IssuesControllerPatch)
  end
  Issue.send(:include, RedmineCustomers::IssuePatch)
  Mailer.send(:include, RedmineCustomers::MailerPatch)
  IssuesController.send(:include, RedmineCustomers::IssuesControllerPatch)
  ContextMenusController.send(:include, RedmineCustomers::ContextMenusControllerPatch)
  WatchersController.send(:include, RedmineCustomers::WatchersControllerPatch)
  User.send(:include, RedmineCustomers::UserPatch)


prepare_block = Proc.new do
  Query.send(:include, RedmineCustomers::IssueQueryPatch)
end

Redmine::Search.map do |search|
  search.register :customers
end

Mime::Type.register "application/xls", :xls
