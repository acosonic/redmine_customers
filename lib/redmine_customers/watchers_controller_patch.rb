# Based on RMP Group Watchers plugin, modified by Aleksandar Pavic (C) 2017 LCP
# Rails 7 port: 2026-06 (Inctime)
# GPL

module RedmineCustomers
  module WatchersControllerPatch
    def autocomplete_for_user
      if params[:object_type].blank? || params[:object_type] == 'issue'
        @users = Principal.member_of(@project).order(:lastname).like(params[:q])
        @users -= @watched.watcher_users if @watched
        render layout: false
      else
        super
      end
    end

    def append
      if params[:watcher].is_a?(Hash) || params[:watcher].is_a?(ActionController::Parameters)
        user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]] || []
        @users = Group.where(id: user_ids).to_a +
                 User.joins("LEFT JOIN groups_users ON groups_users.user_id = #{User.table_name}.id")
                     .active
                     .where(
                       "groups_users.group_id IN (:user_ids) OR #{User.table_name}.id IN (:user_ids)",
                       user_ids: user_ids + [0]
                     )
                     .distinct
                     .sorted
                     .to_a
      end
    end

    def create
      if @watched.is_a?(Issue)
        user_ids = if params[:watcher].is_a?(Hash) || params[:watcher].is_a?(ActionController::Parameters)
                     params[:watcher][:user_ids] || params[:watcher][:user_id]
                   else
                     params[:user_id]
                   end

        params[:watcher] = {}
        params[:watcher][:user_id] = User
                                     .joins("LEFT JOIN groups_users ON groups_users.user_id = #{User.table_name}.id")
                                     .active
                                     .where(
                                       "groups_users.group_id IN (:user_ids) OR #{User.table_name}.id IN (:user_ids)",
                                       user_ids: Array(user_ids) + [0]
                                     )
                                     .distinct
                                     .sorted
                                     .map(&:id)
      end

      super
    end
  end
end
