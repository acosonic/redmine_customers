# Taken from RMP Group Watchers plugin and modified for MNS needs by
# Aleksandar Pavic (C) 2017 (LCP Services agency) http://www.lcpgroup.biz
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module RedmineCustomers
  module QueriesControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do

      end
    end

    module InstanceMethods
      def redirect_to_customer_query(options)
        redirect_to customers_path
      end
    end
  end
end
