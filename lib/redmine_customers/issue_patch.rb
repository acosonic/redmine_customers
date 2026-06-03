# Based on RMP Group Watchers plugin, modified by Aleksandar Pavic (C) 2017 LCP
# Original RMP Group Watchers: (C) 2015 Kovalevsky Vasil (RMPlus)
# Rails 7 port: 2026-06 (Inctime)
# GPL

module RedmineCustomers
  module IssuePatch
    def self.prepended(base)
      base.class_eval do
        belongs_to :customer, optional: true

        safe_attributes 'customer_id',
                        if: lambda { |issue, user|
                          issue.new_record? || user.allowed_to?(:edit_issues, issue.project)
                        }

        delegate :phone, :customer_name, :email, :group,
                 to: :customer, allow_nil: true
      end
    end

    def addable_watcher_users(project = nil)
      if project.nil?
        super()
      else
        Principal.member_of(project).sort - watcher_users
      end
    end

    def watcher_user_ids=(user_ids)
      if user_ids.is_a?(Array)
        user_ids = user_ids.uniq.map(&:presence).compact
        user_ids = User
                   .joins("LEFT JOIN groups_users ON groups_users.user_id = #{User.table_name}.id")
                   .active
                   .where(
                     "groups_users.group_id IN (:user_ids) OR #{User.table_name}.id IN (:user_ids)",
                     user_ids: user_ids + [0]
                   )
                   .distinct
                   .sort
                   .map(&:id)
      end

      super(user_ids)
    end
  end
end
