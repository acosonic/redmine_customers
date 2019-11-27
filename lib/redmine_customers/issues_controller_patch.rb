# Taken from RMP Group Watchers plugin and modified for customers needs by
# Aleksandar Pavic (C) 2017 (LCP Services agency) http://www.lcpgroup.biz
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module RedmineCustomers
  module IssuesControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do

        alias_method :build_new_issue_from_params_without_customers, :build_new_issue_from_params
        alias_method :build_new_issue_from_params, :build_new_issue_from_params_with_customers
      end
    end

    module InstanceMethods
      def build_new_issue_from_params_with_customers
        if params[:id].blank?
          if params[:helpdesk_project_id]
            @project = Project.find(params[:helpdesk_project_id])
            if params[:issue] && params[:issue][:tracker_id]
              tracker = @project.trackers.where(id: (params[:issue] && params[:issue][:tracker_id])).first
              if tracker.nil?
                params[:issue][:tracker_id] = @project.trackers.first.try(:id)
              end
            elsif params[:tracker_id]
              tracker = @project.trackers.where(id: params[:tracker_id]).first
              if tracker.nil?
                params[:tracker_id] = @project.trackers.first.try(:id)
              end
            end
          end
        end
        build_new_issue_from_params_without_customers
        @available_watchers = @issue.assignable_users.to_a
      end


    end
  end
end
