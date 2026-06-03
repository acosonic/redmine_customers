# Based on RMP Group Watchers plugin, modified by Aleksandar Pavic (C) 2017 LCP
# Original RMP Group Watchers: (C) 2015 Kovalevsky Vasil (RMPlus)
# Rails 7 port: 2026-06 (Inctime)
#   - class-method overrides via singleton_class.prepend
#   - bug fix: `customer.try(:email_id)` was always nil (no such field).
#     Customer schema has `email`. Switched to `customer.try(:mail)` which
#     returns `email` (see Customer#mail).
# GPL

module RedmineCustomers
  module MailerPatch
    module ClassMethods
      def deliver_issue_add(issue)
        super
        cc_emails = [issue.customer.try(:mail)].compact
        return if cc_emails.empty?

        users = issue.notified_users | issue.notified_watchers
        users = users.select { |u| cc_emails.include?(u.mail) }
        users.each { |user| issue_add(user, issue).deliver_later }
      end

      def deliver_issue_edit(journal)
        super
        issue = journal.journalized.reload
        cc_emails = [issue.customer.try(:mail)].compact
        return if cc_emails.empty?

        users = journal.notified_users | journal.notified_watchers
        users.select! { |user| journal.notes? || journal.visible_details(user).any? }
        users.each do |user|
          next unless cc_emails.include?(user.mail)
          Mailer.issue_edit(user, journal).deliver_later
        end
      end
    end

    def self.prepended(base)
      base.singleton_class.prepend(ClassMethods)
    end
  end
end
