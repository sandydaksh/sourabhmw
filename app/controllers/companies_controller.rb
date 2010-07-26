require 'RMagick'
class CompaniesController < ApplicationController
  layout 'universities'
  before_filter :admin_required
  # GET /universities
  # GET /universities.xml
  def index
    @companies = Company.find(:all,:conditions => ["data_type = ?","company"])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @companies }
    end
  end

  # GET /companies/1
  # GET /companies/1.xml
  def show
    @company = Company.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.xml
  def new
    @company = Company.new
    @email_domain = EmailDomain.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /companies/1/edit
  def edit
    @company = Company.find(params[:id])
    @company_domains = @company.email_domains
    @company_paths = @company.alt_paths
  end

  # POST /companies
  # POST /companies.xml
  def create
    @company = Company.new(params[:company])
    
    respond_to do |format|
      if @company.save
        if params[:domain]
          params[:domain].each do |d|
            @email_domain = EmailDomain.new
            @email_domain.university_id = @company.id
            @email_domain.domain = d
            @email_domain.save
          end 
        end
        
        if params[:alumni_url]
          params[:alumni_url].each do |d|
            @alt_path = AltPath.new
            @alt_path.university_id = @company.id
            @alt_path.alumni_url = d
            @alt_path.save
          end 
        end
        
        flash[:notice] = 'Company was successfully created.'
        format.html { redirect_to(companies_url) }
        format.xml  { render :xml => @company, :status => :created, :location => @company }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def addbox
    @email_domain = EmailDomain.new
    if session[:i].nil? then
      session[:i] = 0
    end 
    session[:i] =session[:i] + 1
    render :partial => "domainbox",:layout => false
  end
  
  def deletebox
    @ed = EmailDomain.find(params[:domain_id]).destroy if params[:domain_id]
    render :update do |page|
      page.remove "#{params[:id]}"
    end
  end

  def addurlbox
    @email_domain = AltPath.new
    if session[:j].nil? then
      session[:j] = 0
    end 
    session[:j] =session[:j] + 1
    render :partial => "urlbox",:layout => false
  end
  
  def deleteurlbox
    @ed = AltPath.find(params[:url_id]).destroy if params[:url_id]
    render :update do |page|
      page.remove "#{params[:id]}"
    end
  end


  # PUT /companies/1
  # PUT /companies/1.xml
  def update
    @company = Company.find(params[:id])
    @company_paths = @company.alt_paths
    @company_domains = @company.email_domains
    respond_to do |format|
      if @company.update_attributes(params[:company])
        if !@company_paths.blank?
          @company_paths.each_with_index do |d,i|
            AltPath.connection.execute("update alt_paths set alumni_url = '#{params[:alumni_url_old][i]}' where id = #{d.id}")
          end
        else
          params[:alumni_url_old].each do |d|
            @alt_path = AltPath.new
            @alt_path.university_id = @company.id
            @alt_path.alumni_url = d
            @alt_path.save
          end 
        end
        
        if !@company_domains.blank?
          @company_domains.each_with_index do |d,i|
            EmailDomain.connection.execute("update email_domains set domain = '#{params[:domain_old][i]}' where id = #{d.id}")
          end
        else  
          params[:domain_old].each do |d|
            @email_domain = EmailDomain.new
            @email_domain.university_id = @company.id
            @email_domain.domain = d
            @email_domain.save
          end
        end
        
        if !params[:domain].blank?
          params[:domain].each do |d|
            @email_domain = EmailDomain.new
            @email_domain.university_id = @company.id
            @email_domain.domain = d
            @email_domain.save
          end
        end
        
        if !params[:alumni_url].blank?
          params[:alumni_url].each do |d|
            @alt_path = AltPath.new
            @alt_path.university_id = @company.id
            @alt_path.alumni_url = d
            @alt_path.save
          end 
        end
        
        flash[:notice] = 'Company was successfully updated.'
        format.html { redirect_to(companies_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  def email_verify
    if request.post?
      texvalarr = params[:txtvalue].split(',')
      texvalarr.each_with_index do |val,i|
        if val == "true"
          ace = AccountEmail.find(:first,:conditions => ["member_id = ? && university_name = ? && email = ?",params[:email_member][i],params[:univ_name][i],params[:email_value][i]])
          ace.verified = 1
          if ace.save
            flash.now[:domain_verified] = "Selected Emails has been verified successfully."
          end  
        end
      end     
    end
    @univ_nm = University.find(:all,:conditions => ["data_type = ?","company"]).map{|x| x.url}
    unm = ""
    @univ_nm.each do |u|
      if u == @univ_nm.last
        u1 = "'#{u}'"
      else
        u1 = "'#{u}',"
      end
      unm = unm + "#{u1}"
    end
    @emailaccount = AccountEmail.find(:all,:conditions => ["verified = ? and university_name in (#{unm})",0])
  end

  def email_in_multiple
    if request.post?
      email_array = params[:member_emails].split(',') if !params[:member_emails].blank?
      @em_array = []
      if !email_array.blank?
        u = Company.find_by_id(params[:company_value])
        email_array.each do |email|
          m = Member.find_by_email(email)
          if m
            @account = AccountEmail.new()
            @account.member_id = m.id
            @account.verification_code = AccountEmail.random_string(10)
            @account.company_name = u.url
            @account.verified = 1
            @account.email = m.email
            @account.manual_verify = 1
            @account.save
          else
            @em_array << email
          end
        end
      end
    end
    @companies = Company.find(:all,:conditions => ["data_type = ?","company"])
  end
  
  def univ_in_multiple
    if request.post?
      email_array = params[:member_emails].split(',') if !params[:member_emails].blank?
      @em_array = []
      if !email_array.blank?
        m = Member.find_by_email(params[:company_value])
        
        email_array.each do |email|
          u = Company.find_by_url(email)
          if u
            @account = AccountEmail.new()
            @account.member_id = m.id
            @account.verification_code = AccountEmail.random_string(10)
            @account.company_name = u.url
            @account.verified = 1
            @account.email = m.email
            @account.manual_verify = 1
            @account.save
          else
            @em_array << email
          end
        end
      end
    end
  end
  
  # DELETE /companies/1
  # DELETE /companies/1.xml
  def destroy
    @company = Company.find(params[:id])
    #~ @company.destroy 
    Company.connection.execute("update companies set status=0 where id = #{@company.id}") if params[:disable]
    Company.connection.execute("update companies set status=1 where id = #{@company.id}") if params[:enable]
    respond_to do |format|
      format.html { redirect_to(companies_url) }
      format.xml  { head :ok }
    end
  end
end
