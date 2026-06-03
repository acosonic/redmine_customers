# Modified for customers needs by Aleksandar Pavic (C) 2017 LCP Services
# Rails 7 port: 2026-06 (Inctime)
# GPL

module RedmineCustomers
  module QueriesControllerPatch
    def redirect_to_customer_query(options)
      redirect_to customers_path
    end
  end
end
