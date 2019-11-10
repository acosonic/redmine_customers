# customers Custom developed Redmine plugin usage instructions

# Contents of this document:

**Contents of this document:** 	___1

**About**	___1

**Plugin Installation**	___2

**Plugin Usage**	___2

Customers feature:	___3

New Case feature	___5

Customer based Issue filtering 	___7

Reporting feature	___8

Generating a report	   ___10

**Technical documentation:**	 ___11

Reporting bugs	___12


# About

This document is usage instructions for plugin, which is a result of custom Redmine plugin development, based on RFQ Document created by customers in October 2016. Author and responsible person is Aleksandar Pavic, company: LCP Services from Novi Sad, Republic of Serbia - Europe. Author can be contacted via skype: acosonic and e-mail: acosonic@gmail.com



# Plugin Installation

Plugin is installed like any ordinary Redmine plugin with following procedure
a. **Extract contents of customers.zip** file to redmine’s installation directory, subfolder plugins or 
**svn checkout** it, with proper permissions, following users can do it:

| User          | Email          | 
| ------------- |:-------------:| 
| Corinne       | shalini.ramloll@customers.mu |
| Shalini       | shalini.ramloll@customers.mu|
| Parveen       | parveen.peerye@customers.mu    |   
| Maryjane      | maryjane.koo@customers.mu     | 
| Kevin         | kevin.domah@customers.mu |
| Anand         | anand.hujoory@customers.mu | 
| Santosh       | santosh.koonjul@customers.mu |
| Luvin         | luvin.gopaul@customers.mu |
| Ravi          | ravi.mohun@customers.mu  |


The svn checkout IRL is: [https://projects.lcpgroup.biz/svn/customers-custom-redmine-development](https://projects.lcpgroup.biz/svn/customers-custom-redmine-development) 

b. Open command prompt and navigate to redmine’s install directory, then run following command: 
**bundle install**

c. Perform database migration:
**bundle exec rake redmine:plugins:migrate RAILS_ENV=development name=customers**

d. Configure link towards **wickedhtmltopdf** (might require additional installation of  [http://wkhtmltopdf.org/](http://wkhtmltopdf.org/) )  in **init.rb** file of plugin:

![Redmine](images/1.png)

e. Restart Redmine (depends upon your server instance)


# Plugin Usage

Plugin introduces 3 new links at top menu bar: **New Case**, **Report** and **Customers**

![customers ticketing system](images/2.png)

To use plugin, it does not need to be turned on, as “per project” basis, but rather it’s *usage privileges need to be set by administrator* for a particular role under Redmine’s administration:

**Administration | Roles and permissions**

And after that *users that need to operate the plugin must be assigned to at least one project with a role that has the customers permissions*. In order to see links at top menu bar.

![](images/3.png)


### Customers feature:

Offers import of CSV file with Customers, as specified in RFQ document. Adding new Customer manually via form, and editing existing customer records. It introduces also, Customers menu for Redmine Administrators:

![](images/4.png)

**Import CSV feature:**

This feature **APPENDS** customer reports, it will skip existing records, using customer’s user id as unique field. Fields are provided, as per RFQ doc.

So the CSV file to be imported looks like this in excel:

![](images/5.png)

Or if you open it with text editor:

    id,user_id,customer_name,tel_number,email_id,company_name,subscriber_id,tan_number,npf_number,paye_number,vat_number 1,jharris0,Julia,86-(417)654-2633,jjames0@google.es,Skibox,568,879,511,242,84

*Where first field id is irrelevant*! You can put anything. Redmine will automatically assign customer ID’s based on auto increment function.

To perform CSV import, on Import CSV form, click **Upload CSV**

![](images/6.png)


Then, after upload, user is given a form to map CSV fields to plugin’s database fields, in case that CSV file is different from above proposed layout.

![](images/7.png)

Third step, which actually performs import is clicking submit button on Match import screen.
After import, user will be presented with report that will show if something went wrong during import.

![](images/8.png)

If import is successful, green notification will appear, and customers will be browseable thru customers screen, which offers standard Show, Edit, Delete actions.

![](images/9.png)

**Show** - displays customer information, **Edit** offers editing of customer’s details, and **Delete**, removes customer from the system!


### New Case feature

Opens New case entry field, which offers new issues to be assigned to one of Customer Tickets 
Subprojects. Notice the numbering on following image:

![](images/10.png)

This feature consists of following:

 1. Group watchers feature, as per RFQ document, a group can be assigned as a watcher, which actually simulates a behavior, as if operator would be clicking each user of the group individually. This means users will be notified, as if they were added individually.
 2.  Choose system dropdown (automatically redirects to chosen project’s New issue screen)
 3. Choose customer opens customer search box, which offers search that triggers after 3 letters for a customer, and requires customer to be clicked, then add button clicked.
 ![](images/11.png)
 4. Company name and contact info are text fields which can be populated only by choosing customer via button 3.

### Customer based Issue filtering 

Issues can be filtered based on customer introduced fields, which are prepended to Add filter dropdown box.

![](images/12.png)

They can also be chosen in Available columns, and used as Saved queries.

![](images/13.png)


### Reporting feature

Reporting feature is based upon SLA custom field which needs to be set on per-project basis.
SLA custom field is representing a **number of hours** which are defined in service level agreement for that particular project.
So, existence of SLA field is pre-requisite:

 1. SLA Field should be Custom field for Project
 ![](images/14.png)
 2. SLA is of following characteristics:
 ![](images/15.png)
Visible text field limited to numbers. Probably integer type would also work, but code was originally done with text field.




#### Generating a report
The following form is presented, once Report is clicked at top menu bar:
![](images/16.png)

1. Choose system dropdown
2. Choose period with calendar dropdown icon
3. Generate button

Once Generate button is clicked, system automatically, based upon sql queries and mathematics done in plugin’s code generates reports, as requested in RFQ doc. Numbers on image below represents:

1. From-to days, displayed as reference (chosen on report form)
2. Section for SLA status with details and name of project
3. Call priority section
4. % of tickets within SLA defined by number 8
5. Problem type breakdown, based upon Category field from New Case screen
6. Export to PDF
7. Export to XLS (Excel format)
8. SLA, actually read from Project’s custom field setting.

![](images/17.png)

# Technical documentation:

customers Plugin is done for Redmine 2.4.x with rails 3

It can be used on any database supported by Redmine 2.4.x versions.

Plugin is internationalized and can be translated to custom languages, based on Redmine’s standard internationalization. (creation of 2 letter country codes yml files in /config/lang directory.

Plugin modifies Issue database table by adding customer_id field to Redmine’s standard issue table.

It also creates Customers table, with fields described as per RFQ document.

It requires following gems: 

 - gem "wicked_pdf"
 - gem 'rubyzip', '~> 1.1.0'
 - gem 'axlsx', '2.1.0.pre'
 - gem 'axlsx_rails'
 - gem 'wkhtmltopdf-binary', '~> 0.9.9.3'

And requires init.rb file to be updated to fit location of wkhtmltopdf-binary

Class and method documentation can be generated by running:

**rdoc ./ -o ./tmp/doc** 

And HTML documentation will be generated in tmp/doc folder of plugin.

Classes are named with customers prepended, and code is organised into Modules, so it should not cause conflicts with other plugins.

Plugin uses standard hooks and patches, available in Redmine 2.4.x version, they are in /lib folder, as per Redmine’s plugin functioning requirements.

#### Reporting bugs

Following persons can login to LCP Services Redmine:


| User          | Email          | 
| ------------- |:-------------:| 
| Corinne       | shalini.ramloll@customers.mu |
| Shalini       | shalini.ramloll@customers.mu|
| Parveen       | parveen.peerye@customers.mu    |   
| Maryjane      | maryjane.koo@customers.mu     | 
| Kevin         | kevin.domah@customers.mu |
| Anand         | anand.hujoory@customers.mu | 
| Santosh       | santosh.koonjul@customers.mu |
| Luvin         | luvin.gopaul@customers.mu |
| Ravi          | ravi.mohun@customers.mu  |

Under URL: https://projects.lcpgroup.biz/

Bugs can be assigned as in ordinary Redmine, to one of 3 persons from LCP team:
Aleksandar Pavic, Mantahan Damania or Dusan Todorovic.