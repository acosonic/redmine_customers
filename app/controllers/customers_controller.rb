##
#  Redmine 2.4 plugin - customers plugin
#
#  Custom developed 2016,2017 for customers Mauritius
#  Author: Aleksandar Pavic - acosonic@gmail.com
#  LCP Services, Bul. P. Pavla 8/24, 21000 Novi Sad, Serbia
#
#  Copyrighted by LCP and customers, built specifically to be used
#  by customers for their existing Redmine instance
#  Otherwise licensed as GPL (keep the copyright notice)
#
##
class CustomersController < ApplicationController
  unloadable

  helper :sort
  include SortHelper
  require 'csv'


  rescue_from Query::StatementInvalid, :with => :query_statement_invalid


  helper :issues
  helper :custom_fields
  helper :queries
  include QueriesHelper

  before_action :require_login
  before_action :set_customer, :only => [:show, :edit, :update, :destroy, :active, :inactive ]

  before_action :authorize_global

  default_search_scope :customers
  accept_api_auth :show

  def index
    retrieve_query(CustomerQuery)

    if @query.valid?
      respond_to do |format|
        format.html {
          @customer_count = @query.customer_count
          @customer_pages = Paginator.new @customer_count, per_page_option, params['page']
          @customers = @query.customers(:offset => @customer_pages.offset, :limit => @customer_pages.per_page)
          render :layout => !request.xhr?
        }
        format.api  {
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
          @customer_count = @query.customer_count
          @customers = @query.customers(:offset => @offset, :limit => @limit)
          Issue.load_visible_relations(@customers) if include_in_api_response?('relations')
        }
        format.atom {
          @customers = @query.customers(:limit => Setting.feeds_limit.to_i)
          render_feed(@customers, :title => "#{@project || Setting.app_title}: #{l(:label_customer_plural)}")
        }
        format.csv  {
          @customers = @query.customers(:limit => Setting.customers_export_limit.to_i)
          send_data(query_to_csv(@customers, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'customers.csv')
        }
        format.pdf  {
          @customers = @query.customers(:limit => Setting.customers_export_limit.to_i)
          send_file_headers! :type => 'application/pdf', :filename => 'customers.pdf'
        }
      end
    else
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.any(:atom, :csv, :pdf) { head 422 }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new
    @customer.safe_attributes = params[:customer].permit!
    respond_to do |format|
      if @customer.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_customer_path : @customer)
        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
  end

  def active
    @customer.active = true
    @customer.save
    redirect_to @customer
  end

  def inactive
    @customer.active = false
    @customer.save
    redirect_to @customer
  end

  def update
    if @customer.update_attributes(params[:customer].permit!)
      flash[:notice] = "Successfully updated"
    else
      render 'edit'
    end
    redirect_to @customer
  end

  def destroy
    if @customers
      @customers.each do |customer |
        customer.destroy
      end
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:notice] = l(:notice_successful_delete) if  @customer.destroy
    end

    redirect_to :action => :index
  end


  def acfind
    @customers = Customer.where(active: true).limit 100
  end

  def import

  end

##
# First phase of import, only matches CSV fields to Database fields

  def match
    # params
    file = params[:file]
    splitter = params[:splitter]
    wrapper = params[:wrapper]
    encoding = params[:encoding]

    @samples = []
    @headers = []
    @attrs = []

    # save import file
    @original_filename = file.original_filename
    tmpfile = Tempfile.new("customers_customers_import", :encoding =>'ascii-8bit')
    if tmpfile
      tmpfile.write(file.read)
      tmpfile.close
      tmpfilename = File.basename(tmpfile.path)
      if !$tmpfiles
        $tmpfiles = Hash.new
      end
      $tmpfiles[tmpfilename] = tmpfile
    else
      flash.now[:error] = l(:customers_cannot_save_import_file)
      return
    end

    session[:importer_tmpfile] = tmpfilename
    session[:importer_splitter] = splitter
    session[:importer_wrapper] = wrapper
    session[:importer_encoding] = encoding

    # display content
    i = 0
    quote_chars = %w(" | ~ ^ & *)
    begin
      CSV.foreach(tmpfile.path, {:headers=>true, :encoding=>encoding, :quote_char=> quote_chars.shift, :col_sep=>splitter,liberal_parsing: true}) do |row|
        @samples[i] = row
        i += 1
      end # do
    rescue CSV::MalformedCSVError
      quote_chars.empty? ? raise : retry
    rescue => ex
      flash.now[:error] = ex.message
    end

    if @samples.size > 0
      @headers = @samples[0].headers
    end

    # fields
    Customer.customer_attrs.each do |attr|
      @attrs.push([t("customers_#{attr}", default: attr), attr])
    end
  end

##
# Performs actual creation of new CustomersController

  def result
    tmpfilename = session[:importer_tmpfile]
    splitter = session[:importer_splitter]
    wrapper = session[:importer_wrapper]
    encoding = session[:importer_encoding]

    if tmpfilename
      tmpfile = $tmpfiles[tmpfilename]
      if tmpfile == nil
        flash.now[:error] = l(:customers_missing_imported_file)
        return
      end
    end


    # CSV fields map
    fields_map = params[:fields_map].permit!.to_hash
    # DB attr map
    attrs_map = fields_map.invert


    if params[:sync]
      CustomerImport.where(url: params[:url]).delete_all
      ci =  CustomerImport.new
      ci.url = params[:url]
      ci.settings ={encoding: encoding, :splitter=> splitter, attrs_map: attrs_map}
      ci.save
    end
    @handle_count = 0
    @failed_count = 0
    @failed_rows = Hash.new
    quote_chars = %w(" | ~ ^ & *)
    begin
      CSV.foreach(tmpfile.path, {:headers=>true, :encoding=>encoding, :quote_char=> quote_chars.shift, :col_sep=>splitter, liberal_parsing: true}) do |csv_row|
        row = {}
        csv_row.to_h.each do |k, v|
          row[k.to_s.gsub("\"", '')] = v
        end
        contact_id = attrs_map["contact_id"].to_s.gsub(/[^a-zA-Z 0-9]/, '').gsub(/\s/,'-')
        customer = Customer.find_by_contact_id(row[contact_id] ) if row[contact_id].present?
        customer ||= Customer.find_by_email(row[attrs_map["email"]] )  if row[attrs_map["email"]].present?
        customer ||= Customer.new

        customer.customer_name = row[attrs_map["customer_name"] ]
        customer.phone = row[attrs_map["phone"] ]
        customer.email = row[attrs_map["email"] ]
        customer.contact_id = row[attrs_map["contact_id"] ]
        customer.visible_custom_field_values.each do |custom_field_value|
          custom_field_value.value = row[attrs_map[custom_field_value.custom_field.name] ] if attrs_map[custom_field_value.custom_field.name].present?

        end


        if (!customer.save(:validate => false)) then
          logger.info(customer.errors.full_messages)
          @failed_count += 1
          @failed_rows[@handle_count + 1] = row
        end

        @handle_count += 1
      end # do
    rescue CSV::MalformedCSVError
      quote_chars.empty? ? raise : retry
    end

    if @failed_rows.size > 0
      @failed_rows = @failed_rows.sort
      @headers = @failed_rows[0][1].headers
    else
      flash[:notice] = l(:customers_successfull_import)
    end
  end


  def show
    respond_to do |format|
      format.html{}
      format.json{}
    end
  end

##
# Used on Helpdesk form

  def autocomplete_for_customer
    if params[:q].present?
      @customers = Customer.where(active: true).where("LOWER(customers.customer_name) LIKE :acf OR
                                  LOWER(customers.email) LIKE :acf OR

                                  LOWER(customers.phone) LIKE :acf",
                                  :acf => "%#{params[:q]}%")
    else
      @customers = Customer.where(active: true).limit(100)
    end
  end


  private


##
# Internal method for setting global customer

  def set_customer
    if params[:id] &&  params[:id] != "bobo"
      @customer = Customer.find(params[:id])
    end
    if params[:ids]
      @customers = Customer.where(active: true).where(id: params[:ids])
      @customer = @customers.first if @customers.size == 1
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
