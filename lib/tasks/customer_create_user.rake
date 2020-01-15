namespace :redmine do
  namespace :plugins do

    desc <<-END_DESC
        Sync Customer
    END_DESC

    task :customer_create_user => :environment do
      Customer.all.each do |customer|
        customer.create_user
      end
    end
  end
end
