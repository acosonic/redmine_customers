# Based on RMP Group Watchers plugin, modified by Aleksandar Pavic (C) 2017 LCP
# Rails 7 port: 2026-06 (Inctime)
# GPL

module RedmineCustomers
  module IssuesControllerPatch
    def build_new_issue_from_params
      if params[:id].blank? && params[:helpdesk_project_id]
        @project = Project.find(params[:helpdesk_project_id])
        if params[:issue] && params[:issue][:tracker_id]
          tracker = @project.trackers.where(id: params[:issue][:tracker_id]).first
          params[:issue][:tracker_id] = @project.trackers.first&.id if tracker.nil?
        elsif params[:tracker_id]
          tracker = @project.trackers.where(id: params[:tracker_id]).first
          params[:tracker_id] = @project.trackers.first&.id if tracker.nil?
        end
      end

      super

      @available_watchers = @issue.assignable_users.to_a
    end
  end
end
