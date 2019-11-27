# Taken from RMP Group Watchers plugin and modified for customers needs by
# Aleksandar Pavic (C) 2017 (LCP Services agency) http://www.lcpgroup.biz
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module RedmineCustomers
  module WatchersControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method :autocomplete_for_user_without_customers, :autocomplete_for_user
        alias_method :autocomplete_for_user, :autocomplete_for_user_with_customers

        alias_method :append_without_customers, :append
        alias_method :append, :append_with_customers

        alias_method :create_without_customers, :create
        alias_method :create, :create_with_customers
      end
    end

    module InstanceMethods
      def autocomplete_for_user_with_customers
        if params[:object_type].blank? || params[:object_type] == 'issue'
          @users = Principal.member_of(@project).order(:lastname).like(params[:q])
          #Rails.logger.ap @users
          if @watched
            @users -= @watched.watcher_users
          end
          render layout: false
        else
          autocomplete_for_user_without_customers
        end
      end

      def append_with_customers
        if params[:watcher].is_a?(Hash)
          user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]] || []
          @users = Group.where(id: user_ids).to_a + User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active.where("groups_users.group_id in (:user_ids) or #{User.table_name}.id in (:user_ids)", user_ids: user_ids + [0]).uniq.sorted.to_a
        end
      end

      def create_with_customers
        if @watched.is_a?(Issue)
          if params[:watcher].is_a?(Hash)
            user_ids = (params[:watcher][:user_ids] || params[:watcher][:user_id])
          else
            user_ids = params[:user_id]
          end
          params[:watcher] = {}
          params[:watcher][:user_id] = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active.where("groups_users.group_id in (:user_ids) or #{User.table_name}.id in (:user_ids)", user_ids: user_ids + [0]).uniq.sorted.map(&:id)
        end

        create_without_customers
      end
    end
  end
end
