class ContactsController < ApplicationController
  before_filter :login_required
  layout "contacts"
  def index
     check_render_facebook('contacts', :wrapper)
  end
   
  def imported
   
   if(request.post?)
      # Hack to be able to grab the params via HTTPS  but redirect back to the same action without HTTPS after storing them in the session.
      session[:contact_import_params] = params
      javascript_redirect_to(imported_contacts_url(:only_path => false).gsub("https", "http") ) and return
   end
      
    @email_address = session[:contact_import_params][:email_address]
    password = session[:contact_import_params][:password]
    @email_address += ".linkedin" if(session[:contact_import_params][:import_type] == "linkedin")
      
    session[:contact_import_params] = nil
    
    if(@email_address.blank? && password.blank?)
      @error = "You must supply your username and password."
    else
      contacts, @error = get_contacts(@email_address, password)  
    end
    if(@error)      
      flash.now[:error] = @error      
      render :action => 'import' and return
    end
    members = Member.find_all_by_email(contacts.map(&:email).map(&:strip))
    contacts.each do |contact|
      contact.member = ( members.detect{|member| contact.email == member.email})
    end  
        
    @contacts = contacts.group_by{|contact| contact.name.downcase[0...1]}       
  end
  
  def run_import
    emails = params[:email][:addr]
    if(emails)
      if(Hash === emails )
      emails = emails.values.map(&:strip)
      else
        emails = emails.split(",")
      end
      
      emails_to_names = {}
      email_addresses = []
      emails.each do |email|
          if( parts = email.split("::") )
             email_addresses << parts.first
             emails_to_names[parts.first] = parts.last
          else 
            email_addresses << email
          end
      end
      
      contactables = Contact.create_contactables_for_emails(email_addresses)
      current_member.add_contacts(contactables, emails_to_names)
      if( params[:submit] == "notify")
        non_members = contactables.select{|contactable| NonMember === contactable}
        non_members.each do |non_member|
          InvitationNotify.deliver_invite_to_meetingwave(current_member, non_member, params[:email][:note])
        end
      end
      flash[:notice] = "Added #{emails.size} #{emails.size > 1 ? 'contacts' : 'contact'}."
      redirect_to(:action => "index")
    else
      flash[:error] = "No emails selected."
      redirect_to(:action => "import_ed")
    end
  end
  
  private
  require 'net/https'
  def get_contacts(email_address, password)
    contacts = []
    if( RAILS_ENV == 'development' || RAILS_ENV == 'trunk' )
      File.open(File.join(RAILS_ROOT,'tmp','temp_contact.csv')).each do |line|
        next unless(line.match(/.*@.*/))
        name,email = line.strip.gsub(/\"/,"").split(",")
        contacts << OpenStruct.new(:name => name, :email => email)
      end
    else
      response = ""
      begin
        http = Net::HTTP.new('ws1.octazen.com', 443)
        http.use_ssl = true
        http.start do |http|
          request = Net::HTTP::Get.new("/api/abi/fetch/?f=csv&cid=travelerstable&key=tr@vrstb7&email=#{email_address}&pass=#{password}&ip=127.0.0.1")
          response = http.request(request)
          response.value
        end 
      rescue 
        return [], $!.message
      end

      response.body.split(/\n+/).each do |line|
        name,email = line.strip.gsub(/\"/,"").split(",")
        contacts << OpenStruct.new(:name => name, :email => email)
      end
    end
    return contacts, nil       
  end
end
