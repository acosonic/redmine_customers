namespace :redmine do
  namespace :plugins do

    desc <<-END_DESC
        Sync Customer
    END_DESC

  task :customer_create_user => :environment do
      Customer.all.each do |customer|
        firstname = customer.visible_custom_field_values.detect {|cfv| cfv.custom_field.name == 'Firstname'}
        lastname  = customer.visible_custom_field_values.detect {|cfv| cfv.custom_field.name == 'Lastname'}
        oUser=User.new(:firstname => firstname , :lastname  => lastname, :mail  => customer.email)
        oUser.login = customer.email
        oUser.admin = false
        oUser.password = "alma$CAM"
        oUser.must_change_passwd = true
        if !oUser.save
         pp oUser.errors
        else
          member = Member.new
          member.user = User.find_by_login(oUser.login)
          member.project = Project.find(4)
          member.roles = [Role.find_by_name('Customer')]
          member.save
        end
      end
    end
  end
end

