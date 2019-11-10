#
# Redmine 2.4 plugin - customers plugin
#
# Custom developed 2016,2017 for customers Mauritius
# Author: Aleksandar Pavic - acosonic@gmail.com
# LCP Services, Bul. P. Pavla 8/24, 21000 Novi Sad, Serbia
#
# Copyrighted by LCP and customers, built specifically to be used
# by customers for their existing Redmine instance
# Otherwise licensed as GPL (keep the copyright notice)
#
module RedmineCustomers
  module UserPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
      end
    end

    module InstanceMethods
      def membership(project)
        project_id = project.is_a?(Project) ? project.id : project

        @membership_by_project_id ||= Hash.new {|h, project_id|
          h[project_id] = memberships.where(:project_id => project_id)[0]
        }
        @membership_by_project_id[project_id]
      end
    end
  end
end
