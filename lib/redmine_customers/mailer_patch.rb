# Taken from RMP Group Watchers plugin and modified for customers needs by
# Aleksandar Pavic (C) 2017 (LCP Services agency) http://www.lcpgroup.biz
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module RedmineCustomers
  module MailerPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend(ClassMethods)
      base.class_eval do
        class<<self
          alias_method_chain :deliver_issue_add, :customers
          alias_method_chain :deliver_issue_edit, :customers
        end
      end
    end

    module ClassMethods
      def deliver_issue_add_with_customers(issue)
        deliver_issue_add_without_customers(issue)
        cc = [issue.customer.try(:email_id)]
        to = []
        return if cc.empty?
        if Redmine::VERSION::MAJOR >= 4
          users = issue.notified_users | issue.notified_watchers
          users = users & cc
          users.each do |user|
            issue_add(user, issue).deliver_later
          end
        else
          issue.each_notification(to + cc) do |users|
            Mailer.issue_add(issue, to & users, cc & users).deliver
          end
        end

      end

      def deliver_issue_edit_with_customers(journal)
        deliver_issue_edit_without_customers(journal)
        issue = journal.journalized.reload
        cc = [issue.customer.try(:email_id)]
        to = []
        return if cc.empty?
        if Redmine::VERSION::MAJOR >= 4
          users = journal.notified_users | journal.notified_watchers
          users.select! do |user|
            journal.notes? || journal.visible_details(user).any?
          end
          users.each do |user|
            Mailer.issue_edit([user] & cc , journal).deliver_later
          end
        else
          journal.each_notification(to + cc) do |users|
            issue.each_notification(users) do |users2|
              Mailer.issue_edit(journal, to & users2, cc & users2).deliver
            end
          end

        end

      end
    end

    module InstanceMethods

    end
  end
end
