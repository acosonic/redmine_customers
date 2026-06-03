# Rails 7 port: 2026-06 (Inctime)
# Adds `helpdesk` and `update_helpdesk_form` actions to IssuesController.
require_dependency 'issues_controller'

module RedmineHelpdeskCustomers
  module Patches
    module IssuesControllerPatch
      def self.prepended(base)
        base.class_eval do
          prepend_before_action :find_issue_and_project,
                                only: [:helpdesk, :update_helpdesk_form]
        end
      end

      def helpdesk
        @helpdesk_project = Project.find(params[:helpdesk_project_id])
        return unless update_issue_from_params
        return if @helpdesk_project.nil?

        @issue.project = @helpdesk_project
        @issue.author ||= User.current
        @issue.tracker ||= @helpdesk_project.trackers.find(
          (params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first
        )

        if @issue.tracker.nil?
          render_error l(:error_no_tracker_in_project)
          return false
        end

        @issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?
        @issue.safe_attributes = params[:issue]

        @priorities = IssuePriority.active
        @allowed_statuses = @issue.new_statuses_allowed_to(User.current, @issue.new_record?)
        @available_watchers = (@issue.project.users.sort + @issue.watcher_users).uniq
      end

      def update_helpdesk_form
        @helpdesk_project = Project.find(params[:helpdesk_project_id])

        @issue.project_id = @helpdesk_project.id
        @issue.author ||= User.current
        @issue.tracker ||= @helpdesk_project.trackers.find(
          (params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first
        )

        if @issue.tracker.nil?
          render_error l(:error_no_tracker_in_project)
          return false
        end

        @issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?
        @issue.safe_attributes = params[:issue]

        @priorities = IssuePriority.active
        @allowed_statuses = @issue.new_statuses_allowed_to(User.current, @issue.new_record?)
        @available_watchers = (@issue.project.users.sort + @issue.watcher_users).uniq
      end

      def find_issue_and_project
        @issue = Issue.find(params[:id])
        @project = @issue.project
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end
  end
end
