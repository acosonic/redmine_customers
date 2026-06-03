# Custom developed 2016-2017 for customers Mauritius
# Author: Aleksandar Pavic - LCP Services
# Rails 7 port: 2026-06 (Inctime)
# GPL

module RedmineCustomers
  module UserPatch
    def membership(project)
      project_id = project.is_a?(Project) ? project.id : project

      @membership_by_project_id ||= Hash.new do |h, pid|
        h[pid] = memberships.where(project_id: pid)[0]
      end
      @membership_by_project_id[project_id]
    end
  end
end
