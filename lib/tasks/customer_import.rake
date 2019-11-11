namespace :redmine do
  namespace :plugins do

    desc <<-END_DESC
        Sync Customer
    END_DESC

    task :customer_import => :environment do
      CustomerImport.fetch_all
    end
  end
end
