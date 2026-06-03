##
#  Redmine plugin - customers
#
#  Original: custom developed 2015-2016 for client "customers" (Mauritius)
#  Original author: Aleksandar Pavic - acosonic@gmail.com (LCP Services, Novi Sad)
#  Bilel Kedidi: 2019-2020 enhancements (group filter, FR translation)
#  Rails 7 / Redmine 6 port: 2026-06 (Inctime)
#
#  GPL — keep copyright notice
##

require 'redmine'
require_relative 'lib/customers_issues_hook_listener'
require_relative 'lib/redmine_customers/custom_fields_helper_patch'
require_relative 'lib/redmine/field_format/group_format'


Redmine::Plugin.register :redmine_customers do
  name        'Redmine Customers plugin'
  author      'Aleksandar Pavic'
  description 'Customer relationship tracking for Redmine'
  version     '2.0.0'
  url         'https://github.com/acosonic/redmine_plugins'
  author_url  'https://inctime.com'

  requires_redmine version_or_higher: '6.0'

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :customers_customers,
              { controller: 'customers', action: 'index' },
              caption: :label_customer_plural,
              if: Proc.new {
                User.current.logged? &&
                  User.current.allowed_to?(
                    { controller: 'customers', action: 'index' },
                    nil, global: true
                  )
              }
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :customers_customers,
              { controller: 'customers', action: 'index', id: 'customers' },
              caption: :label_customer_plural,
              html: { class: 'icon' }
  end

  Redmine::Search.available_search_types << 'customers'

  permission :view_customers,             customers: :index
  permission :activate_customers,         customers: [:active, :inactive]
  permission :manage_customers,           customers: [:index, :show, :active, :inactive,
                                                      :new, :create, :edit, :update, :destroy]
  permission :add_customers,              customers: [:new, :create]
  permission :create_helpdesk_request,    helpdesk:  :new

  project_module :customers do
    permission :helpdesk, issues: [:helpdesk]
  end

  settings default: { 'default_group_id' => '' },
           partial: 'settings/redmine_customer_setting'
end

Redmine::Search.map do |search|
  search.register :customers
end

Mime::Type.register 'application/xls', :xls unless Mime::Type.lookup_by_extension(:xls)

# Apply monkey-patches. We do this both in to_prepare (for dev mode reloads)
# AND immediately (for production eager-load where to_prepare may not refire).
RedmineCustomersPatches = lambda do
  {
    IssuesController       => [
      RedmineHelpdeskCustomers::Patches::IssuesControllerPatch,
      RedmineCustomers::IssuesControllerPatch
    ],
    Issue                  => [RedmineCustomers::IssuePatch],
    Mailer                 => [RedmineCustomers::MailerPatch],
    QueriesController      => [RedmineCustomers::QueriesControllerPatch],
    IssueQuery             => [RedmineCustomers::IssueQueryPatch],
    ContextMenusController => [RedmineCustomers::ContextMenusControllerPatch],
    WatchersController     => [RedmineCustomers::WatchersControllerPatch],
    User                   => [RedmineCustomers::UserPatch]
  }.each do |target, mods|
    mods.each do |mod|
      target.prepend(mod) unless target.ancestors.include?(mod)
    end
  end
end

# Apply patches directly at plugin load time. Constants resolve via Zeitwerk.
Rails.logger.info "[redmine_customers] applying patches at init.rb load"
RedmineCustomersPatches.call
RedmineCustomers::CustomFieldsHelperPatch.apply!
Rails.logger.info "[redmine_customers] patches applied OK"

# Also re-apply on each dev-mode reload.
Rails.application.config.to_prepare do
  RedmineCustomersPatches.call
  RedmineCustomers::CustomFieldsHelperPatch.apply!
end
