# Taken from RMP Group Watchers plugin and modified for customers needs by
# Aleksandar Pavic (C) 2017 (LCP Services agency) http://www.lcpgroup.biz
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module RedmineCustomers
  module IssuePatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        belongs_to :customer

        alias_method :addable_watcher_users_without_customers, :addable_watcher_users
        alias_method :addable_watcher_users, :addable_watcher_users_with_customers

       alias_method :watcher_user_ids_without_customers=, :watcher_user_ids=
        alias_method :watcher_user_ids=, :watcher_user_ids_with_customers=


        #this is required because otherwise Redmine treats it as a hacking attempt (forbidden parameter)
        safe_attributes 'customer_id', :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
        delegate :phone, :customer_name, :email, :group, to: :customer, allow_nil: true
      end
    end

    module InstanceMethods

      #def custom_values
      #  o = [super]
      #  o += customer.try(:custom_values) if customer&.active
      #
      #  CustomValue.where(id: o.flatten.compact.map(&:id))
      #end

      def addable_watcher_users_with_customers(project = nil )
        if project.nil?
          addable_watcher_users_without_customers
        else
          users = Principal.member_of(project).sort - self.watcher_users
        end
      end

      def watcher_user_ids_with_customers=(user_ids)
        if user_ids.is_a?(Array)
          user_ids = user_ids.uniq.map(&:presence).compact
          user_ids = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active.where("groups_users.group_id in (:user_ids) or #{User.table_name}.id in (:user_ids)", user_ids: user_ids + [0]).uniq.sort.map(&:id)
        end

        send :watcher_user_ids_without_customers=, user_ids
      end
    end
  end
end
