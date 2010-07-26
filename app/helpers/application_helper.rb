 # Methods added to this helper will be available to all templates in the
# application.

require_dependency 'seo_settings'
require 'recaptcha'
require 'metro_areas'
#require 'metro_areas_home1'
#require 'metro_areas_home2'

 
module ApplicationHelper
  include MetroAreas
 
  
  include ReCaptcha::ViewHelper
  include Localization
  include SeoSettings
  include GoogleMapHelper
  include HelpBubblesHelper



# This could be better if we detected there being a hash at the end
# And handled the case when other stylesheets are cached
  def stylesheet_link_tag(*styles)
    if (@cached_stylesheets )

       @cached_stylesheets = @cached_stylesheets.concat(styles)
           "<!-- #{super(*styles)} -->"
    else
      super(*styles)
    end
  end

  def start_caching_stylesheets
    @cached_stylesheets = []
  end

  def cached_stylesheet_link_tag
       if( @cached_stylesheets )
        styles = @cached_stylesheets
                @cached_stylesheets = nil

        tag =  stylesheet_link_tag(styles, :cache => "cached/#{params[:controller]}_#{params[:action]}")
        
       end

  end
   
  def link_to(name, options, html_options = {})  
    if( rel = (html_options[:rel] || html_options["rel"]) )
      #~ foo if(RAILS_ENV == 'development')
    elsif( !(follow_link?(options, html_options)))
      html_options["rel"] = "nofollow"
    end
    super(name, options, html_options)
  end
  
  def follow_link?(options, html_options)
    return true if html_options.delete(:follow)
    
    url = url_for(options)
    if(url.match(/(invitations.*?show.*?)|(blog)|(news$)|(browse$)|(page=\d+)$/))
      return true
    end
    return false
  end
  ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance| "<span class='fieldWithErrors'>#{html_tag}</span>" }

  WELCOMES = %w{ Hej Aloha Salut Hello Hi Ciao Hoi Shalom Hallo Annyong Namaste Hei Ola }

  TAGLINES = [ 'Connect with People. Anytime. Anyplace.', 'The How for Who What Where When and Why' ] 
 
 
  
  # ###############################################################################
  # Used in emails to add the absolute path to an image. APPLICATION_URL is
  # definded in the env files.
  def add_application_url( url )
    if( url.match(%r/http/) || url.match(%r/ftp/) )
      url
    else
      url = APPLICATION_URL + url
    end
  end


  def welcome
    WELCOMES[ WELCOMES.size * rand]
  end

  def tagline(klass)
    tag = (TAGLINES[ TAGLINES.size * rand]).dup
    tag << content_tag('span', 'SM', :class => 'super')
    return content_tag('div', tag, :class => klass)
  end   

  def just_tag
    tag = (TAGLINES[ TAGLINES.size * rand]).dup
  
  end
  
  def show_create_your_profile_button(viewer)
    is_myinvs = (controller.action_name == 'myinvitations')
    is_myacct = (controller.controller_name == 'member' and controller.action_name == 'edit')
    return ((is_myacct or is_myinvs) and (viewer  and (viewer.member_profile.blank? or viewer.member_profile.pretty_empty?)))
  end

  def selected_class?(action)
    case action
    when :my_invites
      con_name = controller.controller_name
      act_name = controller.action_name
      return ((["myinvitations", "archive"].include?(act_name) or ['drafts', 'calendar'].include?(con_name)) ? "subnav_on" : "")
    when :browse
      return ((controller.controller_name == "browse") ? "subnav_on" : "")
    when :post_invite
      return ((controller.controller_name == "post_invite") ? "subnav_on" : "")
    when :my_account
      return ((controller.controller_name == "member" and controller.action_name == "edit") ? "subnav_on" : "")
    when :profile
      return ((controller.controller_name == "member_profiles" and controller.action_name == "edit") ? "subnav_on" : "")
    else
      return ""
    end
  end
  
  def nav_selected?(action)     
    klass =  (controller.action_name.match(/#{action.to_s}/)) ? "subnav_on" : ""
    return klass
  end

  def my_invites_selected_class?(action)
    case action
    when :dashboard
      return ((controller.action_name == 'myinvitations') ? "subnav_on" : "")
    when :archive
      return ((controller.action_name == 'archive') ? "subnav_on" : "")
    when :drafts
      return ((controller.action_name == 'list') ? "subnav_on" : "")
    when :calendar
      return ((controller.controller_name == 'calendar') ? "subnav_on" : "")
     
    else
      return ""
    end
  end

  def drafts_button
    txt = "Drafts"
    txt << " (#{@viewer.drafts.size})" unless @viewer.drafts.size.zero?
    link_to(txt, drafts_url) 
  end  

  def openwave?
    return (session[:openwave] == true)
  end
  
  def error_messages_for(object_name, options = {})
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}") 
    result = ''
    if object && !object.errors.empty?
      options[:header_tag] ||= "h4"
      options[:id] ||= "errorExplanation"
      options[:class] ||= "errorExplanation"
      options[:header] ||=  "The following errors prohibited this #{object_name.to_s.gsub("_", " ")} from being saved"
      header = content_tag( options[:header_tag], options[:header])    
      error_attributes = []
     
      object.errors.each { |attr, msg| error_attributes << attr unless error_attributes.include?(attr) }
      options[:attributes_order] ||= error_attributes
      errs_added = 0
      options[:attributes_order].each do |attr|
      msg = Array(object.errors.on(attr)).first
      
      unless msg.blank? 
         
         if msg.starts_uppercase?
            result << content_tag('li', msg)
            errs_added += 1
          else
            if options[:user_facing_names] and options[:user_facing_names][attr.to_sym]
              name = options[:user_facing_names][attr.to_sym]
            else
              name = ActiveRecord::Base.human_attribute_name(attr.to_s)
            end
            result << content_tag('li', "#{name} #{msg}")
            errs_added += 1
          end
        end
      end
      return "" if errs_added.zero?
      # Array(object.errors.on_base).each { |err| result << content_tag('li', err)
      # }
      result = content_tag("ul", result, :class => "errors")
      result = content_tag('div', header + ' ' + result, "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation")
    end
    result << "<style type=\"text/css\" >  .fieldWithErrors input, .fieldWithErrors select, input.fieldWithErrors  { background-color: #fdbf7d; } </style>"
    result
  end
  
  def error_messages_for_picture(object_name, options = {})
  
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}") 
    result = ''
    if object && !object.errors.empty?
      options[:header_tag] ||= "h4"
      options[:id] ||= "errorExplanation"
      options[:class] ||= "errorExplanation"
      options[:header] ||=  ""#"The following errors prohibited this #{object_name.to_s.gsub("_", " ")} from being saved"
      header = content_tag( options[:header_tag], options[:header])    
      error_attributes = []
      object.errors.each { |attr, msg| error_attributes << attr unless error_attributes.include?(attr) }
      options[:attributes_order] ||= error_attributes
      errs_added = 0
      
        result << content_tag('li', "The following errors prohibited this #{object_name.to_s.gsub("_", " ")} from being saved")
        options[:attributes_order].each do |attr|
        msg = Array(object.errors.on(attr)).first
        unless msg.blank? 
        
        if msg.starts_uppercase? 
            result << content_tag('li', msg)
            errs_added += 1
          else
            if options[:user_facing_names] and options[:user_facing_names][attr.to_sym]
              name = options[:user_facing_names][attr.to_sym]
            else
              name = ActiveRecord::Base.human_attribute_name(attr.to_s)
            end
            result << content_tag('li', "#{name} #{msg}")
            errs_added += 1
          end
        end
        
      end

      return "" if errs_added.zero?
      # Array(object.errors.on_base).each { |err| result << content_tag('li', err)
      # }
      result = content_tag("ul", result, :class => "errors")
      result = content_tag('div', header + ' ' + result, "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation")
    end
    result << "<style type=\"text/css\" >  .fieldWithErrors input, .fieldWithErrors select, input.fieldWithErrors  { background-color: #fdbf7d; } </style>"
    result
  end  

  def get_profile(member)
    @member_profile = member.member_profile
    if !@member_profile.nil?
      render :partial => 'member_profiles/show', :locals => { :member_profile => @member_profile }
    elsif @member == session[:member]
      return "You haven't set up your member profile. Setting up a detailed member profile will increase the response rates to your invitations. Use the profile link in the upper right hand corner after you login, or take care of it <b>#{link_to 'now', { :controller => 'member_profiles', :action => 'edit' }, :onclick => "this.href = this.href + '?client_tz_offset=' + timeZoneOffset();" }</b>."
    else
      return 'This member hasn\'t created a profile yet.'
    end
  end

  def make_plural(count, singular, plural = nil)
    if count == 1
      singular
    elsif plural
      plural
    elsif Object.const_defined?("Inflector")
      Inflector.pluralize(singular)
    else
      singular + "s"
    end
  end
  
  def plural_suffix(plural)
    singular = plural.to_s.singularize
    while plural.match(singular).nil?
      singular.chop!
    end
    return plural.match(singular).post_match
  end

  def oneday?(start_time, end_time)
    return true if start_time.to_date == end_time.to_date
  end
  
  def selected_options(object, method)
    # Takes an object and a method name passed as a string Returns an array of
    # object ids or an empty array if nil
    object.nil? ? [] : object.send(method.pluralize).collect { |m| m.id }
  end

  def location_input(opts = {})
    if params[:action] == 'new'
      opts.merge!({:value => '(e.g., restaurant name)', :style => 'color: #777;',
          :onfocus => "clear_e_g_input('(e.g., restaurant name)', 'address_name');",
          :onblur  => "restore_e_g_input('(e.g., restaurant name)', 'address_name');" })
      return text_field('address', 'name', opts)
    else
      return text_field('address', 'name', opts)
    end
  end

  def tool_tip(tt_header, tt_text, tt_opts = {}) 
    id = tt_opts[:id]
    tt_opts[:image] ||= '/images/ttb/questionmark.postwiz.gif'
    result = image_tag(tt_opts[:image], :id => "activator_#{id}", :class => tt_opts[:image_class], :style => tt_opts[:style], :title => "Help", :alt => "Help")
    tip = content_tag('h3', tt_header)
    tip << link_to(image_tag("/images/ttb/button_close.gif"), "#", :class => 'close')
    tip = content_tag('div', tip, :class => 'tt_header')
    tip << content_tag('p', tt_text)
    tt_opts.merge!(:class => 'tooltip')
    result << content_tag('div', tip, tt_opts)
    result
  end
  
  def define_local_ac_options_array(field_name)
    model_class = Kernel.const_get(field_name.camelize)
    all_choices = model_class.send(:find, :all)
    choices_names = all_choices.collect { |ch| "\"#{ch.name}\"" }
    result = "var #{local_ac_opts_array_name(field_name)} = "
    result << "[ #{choices_names.join(',')} ]; "
    javascript_tag(result)
  end
  
  def local_ac_opts_array_name(field_name)
    field_name = 'job' if field_name == 'profession'
    field_name = 'employer' if field_name == 'current_employer' or field_name == 'past_employer'
    "#{field_name.upcase}_OPTIONS"
  end
  
  def local_autocompleter(type_name, field_name, num=nil)
    result = "new Autocompleter.Local('#{type_name}_#{field_name}"
    result << "_names_#{num}" unless num.nil?
    result << "', '#{type_name}_#{field_name}"
    result << "_names_#{num}" unless num.nil?
    result << "_auto_complete', #{local_ac_opts_array_name(field_name)}, "
    result << "{tokens:',', frequency:0.1}); "
    javascript_tag(result)
  end

  def short_link(invitation, meeting = nil, truncation_length = 45)    
    meeting_id = (meeting.nil? ? 'next' : meeting.id)
    link_to(truncate(invitation.name, truncation_length), show_invite_url(:id => invitation, :meeting_id => meeting_id)) 
  end
  
  def formatted_geoip_loc 
    state = (@geoip_location.country == "United States" ? @geoip_location.state : @geoip_location.country)
	if state
      "#{@geoip_location.city}, #{state}"
	 else
	   "Invalid location"
	 end 
  end

  def date_selector(field_name, value, opts = { })
    if value.blank? and !opts[:no_eg_text]
      value = Invitation::DATE_TEMPLATE_TEXT
      style = 'color: #BBBBBB;'
    else
      value = (value.strftime("%m/%d/%Y %I:%M %p") rescue '') unless value.is_a?(String) 
      style = ''
    end
    
    use_opts = {:time => true, 
      :class => 'fatinput',
      :before_close => 'catcalc(\'' + field_name + '\');',
      :onfocus => "clear_e_g_input('#{Invitation::DATE_TEMPLATE_TEXT}', '#{field_name}');",
      :onblur  => "restore_e_g_input('#{Invitation::DATE_TEMPLATE_TEXT}', '#{field_name}');",
      :onchange => "restore_e_g_input('#{Invitation::DATE_TEMPLATE_TEXT}', '#{field_name}');",
      :style => style }.merge(opts)
        		  
    opts[:class] << " fieldWithErrors" if opts[:error]
    calendar_date_select_tag(field_name, value, use_opts)  
  end

  def simple_time_select(name, time = Time.now)
    hours = [ '12 AM', ' 1 AM', ' 2 AM', ' 3 AM', ' 4 AM', ' 5 AM', ' 6 AM', ' 7 AM', ' 8 AM', ' 9 AM', '10 AM', '11 AM', 
      '12 PM', ' 1 PM', ' 2 PM', ' 3 PM', ' 4 PM', ' 5 PM', ' 6 PM', ' 7 PM', ' 8 PM', ' 9 PM', '10 PM', '11 PM' ]
    minutes = [ '00', '15', '30', '45']
    current_hour = time.hour
    hour_opts = options_for_select(hours, hours[current_hour])
    current_minute = time.min
    selected_minute = (minutes.select{|min| min.to_i > current_minute}.first || '00')
    minute_opts = options_for_select(minutes, selected_minute)
    result = select_tag("#{name}[hour]", hour_opts, :class => 'simple_date_select' )
    result << ":"
    result << select_tag("#{name}[minute]", minute_opts, :class => 'simple_date_select')
    return result
  end
   
   
  def select_year_tag(y, options = {})
    start_year, end_year = (options[:start_year] || y-5), (options[:end_year] || y+5)
    step_val = start_year < end_year ? 1 : -1
    year_options =  (options[:include_blank] ? %(<option value=""></option>\n)  : '')
    start_year.step(end_year, step_val) do |year|
      year_options << ((y == year) ?
        %(<option value="#{year}" selected="selected">#{year}</option>\n) :
        %(<option value="#{year}">#{year}</option>\n)
      )
    end
    select_tag(options[:name], year_options, :class => options[:class])
  end
   
  def full_production_environment?
    return (RAILS_ENV == 'production' and (File.expand_path(RAILS_ROOT)).starts_with("/data/travelerstable"))
  end
   
  def preselected_tt_html
    %q{
       <p>
       <span style="font-weight: bold;">The email addresses you provide here of people you know will not be published by the site or 
       disclosed to other users.  Therefore, the email addresses you provide here to pre-select individuals for your proposed meeting 
       will be maintained confidential by our site.</span>
       MeetingWave.com will send an invitation to each listed email address informing the recipient that they have been invited to 
       your proposed meeting and requesting that they either accept or decline the invitation.  You will be notified via email when 
       they accept or decline your invite (you can also check the status on your My Invites page).  If you do not receive a response 
       from the recipient within a reasonable time period, please contact the recipient directly via email or via phone since the 
       notification email from MeetingWave.com may have been blocked by the recipient's email filter or placed in the recipients' 
       Bulk, Spam or Junk folder.  As you may know, the volume of spam has been growing rapidly.  As a result,  more aggressive spam 
       filters are being deployed. These spam filters have an unfortunate side effect of blocking legitimate email, especially marketing, 
       transactions, and customer communications.  Many content-based filters destroy or quarantine messages without the sender or 
       recipient ever knowing!   MeetingWave.com is working on this problem.  In the meantime,  it would be helpful if users and invited 
       recipients take the following steps when they recieve an email from MeetingWave.com:
       </p>
       <p>To ensure you receive the emails you want or need to receive, not only 
     		from <a href="http://www.meetingwave.com">MeetingWave.com</a> but 
     		from other legitimate email senders, we recommend you do the following: 
     		<ul>
     			<li>Check your Bulk or Junk or spam folders periodically for false positives (i.e., legitimate 
     				emails improperly flagged as spam) and designate any legitimate emails found in those  folders as "not spam".
     				<li>Move any legitimate emails to your inbox.
     				<li>Save the sender's email address in your email address book.
     		    <li>If possible, adjust the settings on your spam filter to (a) save (rather than destroy) 
       				filtered email for at least two weeks to allow you to review and correct any false positives; 
       				(b) move any emails that are not spam to your inbox; and (c) automatically add such email 
       				addresses to your email address book to prevent being filtered in the future.
     		</ul>
       
       .  
       
    }
    
  end

  def purposes_tt_html
    %q{<ul>
				<li><b>Business- networking</b> - meet with other individuals within your industry or within your profession for general business networking and contact generation.</li>
				<li><b>Business - provide marketing/sales info</b> - meet with other individuals to provide them with information about a product or service. For example, a trusts attorney may post an invitations to have coffee with individuals interested in learning about trusts and wills.</li>
				<li><b>Business - receive marketing/sales info</b> - meet with one or more individuals to provide you with information about a product or service. For example, post a meeting with a financial advisor to learn about investment strategies or with a patent attorney to learn whether your invention is patentable.</li>
				<li><b>Career Inquiry</b> - Meet with others to discuss a possible career. For example, meet with a high school teacher to learn about teaching high school.</li>
				<li><b>Job Inquiry</b> - Meet with current or former employees at a company you may be interested in working at.</li>
				<li><b>Social - networking</b> - make new friends and acquaintances.</li>
				<li><b>Social - hobby</b> - meet with fellow hobbyists such a fellow card players, bird watchers, gamers, etc.</li>
				<li><b>Social - religious</b> - meet with others who share your faith.</li>
				<li><b>Social - political meeting</b> - meet with others who share your political leanings or learn from others who don't.</li>
				<li><b>Social - Pro-sports fans</b> - rally with fellow fans at a favorite sportsbar or at the hotel bar.</li>
				<li><b>Social - College sports fans</b> - rally with fellow fans at a favorite sportsbar or at the hotel bar.</li>
				<li><b>Social - Alumni</b> - meet with other alumni from your high school, college or graduate school.</li>
				<li><b>Social - same hometown</b> - Connect with someone from your hometown.</li>
				<li><b>Social - Intellectual Discussion</b>- have an intellectual discussion with others to discuss one or more topics interest, such as the civil war, theoretical physics, finance, etc.</li>
				<li><b>Romance</b> - arrange a meeting that is romance or romance-related.</li>
			</ul>}
  end
   
  def email_tt_html
    "<span style='font-weight: bold;'>Your email address will not be published or disclosed to other users unless you include it in your public profile, in an invite or other public location.</span> 
   We will use your email to send notifications to you including an initial verification email to complete your registation and notifications regarding invites you have posted or accepted. 
   For more information, please see our #{link_to('Terms of Use', tos_url)} and #{link_to('Privacy Policy', pp_url)}."
  end

  def private_tt_html
    %q{ 
      I do not want to publish this invite, but rather, set up a private invite that is sent only to individuals that I specify.   I understand that my private invite 
      will only be viewable by these individuals and will not be published on MeetingWave.com or included in results of searches conducted by other users.  
    }
  end
   
  def reminder_settings_html
    %q{ When you click on the reminder checkbox next to an invitation, indicating that you would like a reminder sent to you, then the reminder
      will be sent according to the default setting that you enter here.  For example, if you select "1 hour" from this dropdown list, then any reminders you create by clicking
      the checkboxes will be sent one hour before the meeting time.  You can configure reminder settings for a specific invite by visiting the invite details page for that invite.
    }
  end

  def reminder_settings_on_details_page_html
    %q{ You can change the reminder that will be sent out for this meeting here.  By selecting a different time from the dropdown box below, you affect only the reminder for this meeting.  Other reminders will not be affected.}
  
  end
   
  def include_message_html
    %q{ This message will only be sent to invitees you specify, if any, in this invite and will not be published with the invite or forwarded to other users. }
  end

   
  def js_date(ruby_date)
    return "new Date(#{ruby_date.year}, #{ruby_date.month - 1}, #{ruby_date.day}, #{ruby_date.hour}, #{ruby_date.min}, #{ruby_date.sec})"		
  end    

  def js_future_dates(invitation)
    meetings = invitation.future_meetings
    js_array = meetings.map(&:start_time_local).collect{|time| js_date_idx(time)}.to_json
  end    
	
  def js_future_meetings(invitation)
    meetings = invitation.future_meetings
    js_array = meetings.collect(&:id).to_json
  end
	
  def js_future_meetings_to_dates(invitation)
    meetings = invitation.future_meetings
    js_hash = { }
    meetings.each do |meeting|
      js_hash[meeting.id] = js_date_idx(meeting.start_time_local)
    end
    return js_hash.to_json
  end
  
  def js_future_dates_to_meetings(invitation)
    meetings = invitation.future_meetings
    js_hash = { }
    meetings.each do |meeting|
      js_hash[js_date_idx(meeting.start_time_local)] = meeting.id
    end
    return js_hash.to_json
  end
	
   
  def js_date_idx(ruby_date)
    month = ruby_date.month - 1
    return "#{ruby_date.year}#{month.to_s.rjust(2, '0')}#{ruby_date.day.to_s.rjust(2, '0')}"
  end

  def who_types_html
    %q{
       <h4>Public Invite</h4>
       <p>
         A <b>public</b> invite is publicly available for anyone to accept.  However, you must approve or decline 
         any acceptance of your public invite for any reason since <span style="font-weight: bold; font-style: italic;">you decide who attends your meeting</span>.  
         You do not need to approve the acceptance of anyone you invite to your meeting.
  		</p>
      <h4>Private Invite</h4>
      <p>
        A <b>private</b> invite is not publicly visible on MeetingWave.  Only the users you select will receive a 
        notification for a private invite.  You will not need to approve the acceptance of any users you select.
      </p>
    }

  end
   
  def sh_date(time)
    time.strftime("%b %d") rescue '--'
  end

  def short_time(meeting)
    if meeting.start_time < Time.now.utc
      return "<b>Right Now</b>"
    else
      return meeting.start_time_local.strftime("%b %d, %Y") rescue '--'
    end
  end

  def mobile_time(meeting)
    if meeting.end_time.utc < Time.now.utc
      return "<b>Expired</b>"
    elsif meeting.start_time.utc < Time.now.utc
      return "<b>Now</b>"
	else
      return meeting.start_time_local.strftime("%m/%d/%y") rescue '--'
    end
  end
   
  def sh_date_yr(time)
    time.strftime("%b %d, %Y") rescue '--'
  end
   
  def esc(str)
    return str.gsub(/'/, "\\\\'")
  end     
   
   
   
  def undisclosed_address_image_tag(context)
    image_tag("ttb/lock.#{context}.gif", :alt => l(:undisclosed_address), :title => l(:undisclosed_address))
  end

  def can_see_address_details(inv)
    if( inv.undisclosed_address?  )
      return((@member && @member.can_see_address_details(inv) || @viewer && @viewer.can_see_address_details(inv)) )
    else
      return true
    end
  end

  def undisclosed_location_detail(addr, context)    
    result = ""   
    case addr.kind
    when "airport"
      result <<  addr.display_name 
      result << " " + undisclosed_address_image_tag(context)  << content_tag('br')
    
      result << city_state_country(addr)
    else
      result << city_state_country(addr)
      result << " " + undisclosed_address_image_tag(context) 
		     
    end    
		
    result << content_tag('br')
  end
  
  def undisclosed_location_detail_new(addr)    
    result = ""   
    case addr.kind
    when "airport"
      result <<  addr.display_name 
      #result << " " + undisclosed_address_image_tag(context)  << content_tag('br')
    
      result << city_state_country(addr)
    else
      result << city_state_country(addr)
      #result << " " + undisclosed_address_image_tag(context) 
		     
    end    
		
    result << content_tag('br')
  end

  # This up here to be used in invitation and browse
  def city_state_country(addr, opts = { :zip => true})
    addr = addr.airport   if(addr.airport? && addr.airport )
    zip = addr.zip  if opts[:zip] and addr.respond_to?('zip')
    ci_st_co = [addr.city, addr.state, zip, addr.country].delete_if{ |a| a.blank? }
    ci_st_co.join(', ').sub(/, United States$/, '')
  end

  def status_for(conf)
    return 'Invited' if conf.nil?
    conf.invitation.expired? ? content_tag('span', 'EXPIRED', :class => 'expired') : conf.status.simple_name
  end
    
  def meta_description
    seo_meta_description_for(params)
  end

  def seo_keywords
    seo_keywords_for(params)
  end
    
  def title_tag
    "<title>#{ seo_title_for(params) }</title>"
  end

  def location_format_short(inv, truncate_length = 0)
    return '' if inv.address.nil?
    addr = (inv.address.airport || inv.address)
    ci_st_co = [addr.city, addr.state, addr.country].delete_if{ |a| a.blank? }
    if truncate_length.zero?
      return ci_st_co.join(', ').sub(/, United States$/, '')
    else
      return truncate(ci_st_co.join(', ').sub(/, United States$/, ''), truncate_length)
    end
  end

  # Networkers for home page
  # 
  def wave_makers
    LookUp::profiles_for_wavemakers_on_home
  end
		 
  # This is here so that we might be able to cache the other invites widget
  def setup_other_invites
    @other_invites = @current_member.posted_invites
    @other_invites.delete(@invitation) if @invitation
    @other_meetings = @other_invites.collect { |inv| (inv.upcoming_meeting || inv.meetings.first) }.flatten
  end        
		
  def feed_params(geoip_loc = @geoip_location) 

    sf = SearchFilter.new(:city => geoip_loc.city, 
      :state => geoip_loc.state, 
      :zip => geoip_loc.zip,
      :start_date => Time.now,
      :radius => 50)  
					 
    @feed_params = sf.to_rss_params  
			
  end  
  
  def logged_in?
   !current_member.nil?
  end

		
  def rss_link_tag(feed_params = nil)
    feed_params ||= feed_params() 
			 
    auto_discovery_link_tag(:rss, ssearch_url(feed_params), {:title => "RSS"}) unless feed_params.nil?
  end   
		
  def rss_image_link_tag
    link_to(image_tag('/images/ttb/feed.gif', :class => 'feed_icon'), ssearch_url(feed_params()), :id => 'my_location_feed')
  end

  def rss_atom_button
    link_to(image_tag('/images/meetingwave/buttons/rss.gif', :class => 'feed_icon'), ssearch_url(feed_params()), :id => 'my_location_feed')
  end
	 
   

  def context?(context)    
    if( params[:context].nil?  && params[:fb_sig_session_key])  
      params[:context] = :social_network
    end
    return (params[:context].to_s == context.to_s  )
  end      
  def fb_app_name
    ENV["FACEBOOK_APP_NAME"]
  end
      
  def bebo_request?
    Facebooker.current_adapter.is_for?(:bebo)
  end
  
  def pop_to_facebook(facebook_url,site_url)
   context?(:social_network) ? "javascript:parent.location='#{facebook_url}'" : site_url
  end
  
  
  def pop_from_iframe(url)
    if(params[:fb_sig])
        val = " javascript:parent.window.location.href='#{url}' "
    else
      val = url
    end
    
   return val
  end
 
  def analytics_key
   context?(:social_network) ? "UA-1965013-2" : "UA-1965013-1"
  end
  
  def fb_sig_session_key_hack()
    "<script> var fb_sig_session_key = '#{params[:fb_sig_session_key]}' </script>"
  end
      
      
  def check_render_rating(asset)
    ( stylesheet_link_tag('ttb/ratings.css') + render( :partial => "/admin/quality/rate" , :locals => { :asset => asset}))  if(current_member && current_member.administrator and session[:score_inline])
  end

  def check_render_romance(asset)
    ( render( :partial => "/admin/quality/romance_maker" , :locals => { :asset => asset, :inv => asset}))  if(current_member && current_member.administrator and session[:score_inline])
  end
 
  def indicator_path(name)
    "/images/meetingwave/indicators/#{name}.gif"
  end
  def candy_path(name)
    "/images/meetingwave/candy/#{name}.gif"
  end
 
  def indicator_image(name, opts ={})
    image_tag(indicator_path(name), opts)
  end

  def candy_image(name, opts ={})
    image_tag(candy_path(name), opts)
  end
  
  def logo_path(name, opts = {})
    "/images/meetingwave/logos/#{name}.gif"
  end
 
  def logo_image(name, opts = {})
    image_tag(logo_path(name), opts)
  end
  
  def button_path(name, opts = {})
    off = opts.delete(:off)

    button_name =  (name + (off ? "_off" : "" ) + ".gif")
    "/images/meetingwave/buttons/#{button_name}" 
  end
 
 
  def button_path_new(name, opts = {})
    off = opts.delete(:off)

    button_name =  (name + (off ? "_off" : "" ) + ".gif")
    "/images/meetingwave/buttons/#{button_name}" 
  end
 
 
       
  def off_button_path(name)
    button_path(name , :off => true)
  end
       
  def button_image(name, opts = {})
    image_tag(button_path(name), opts)
  end
  
  def button_image_save(name, opts = {})
    image_submit_tag(button_path(name, opts), :src=>"/images/meetingwave/buttons/#{name}.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/save_small-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/save_small.gif';") 
    #image_tag(button_path(name), opts)
  end
  
  def button_image_delete(name, opts = {})
    image_submit_tag(button_path(name, opts), :src=>"/images/meetingwave/buttons/#{name}.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/#{name}-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/#{name}.gif';") 
    #image_tag(button_path(name), opts)
  end

  
  def button_image_update(name, opts = {})
    image_submit_tag(button_path(name, opts), :src=>"/images/meetingwave/buttons/#{name}.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/update-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/update.gif';") 
    #image_tag(button_path(name), opts)
  end
  
  def button_image_cancel(name, opts = {})
    image_submit_tag(button_path(name, opts), :src=>"/images/meetingwave/buttons/#{name}.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/cancel_small-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/cancel_small.gif';") 
    #image_tag(button_path(name), opts)
  end  
  
  def yelp_button_image(name, opts = {})
    image_tag(yelp_button_path(name), opts)
  end
  
  def yelp_button_path(name, opts = {})
    off = opts.delete(:off)

    button_name =  (name + (off ? "_off" : "" ) + ".jpg")
    "/images/newdesign/#{button_name}" 
  end
       
  def off_button_image(name, opts = {})
    opts[:off] = true
    button_image(name, opts)
  end
      
  def ibutton(name, opts = { })
    image_submit_tag(button_path(name, opts), opts) 
  end
  
  def new_ibutton(name, opts = { })
    image_submit_tag(new_button_path(name, opts), opts) 
  end

  def new_button_path(name, opts = {})
    off = opts.delete(:off)

    button_name =  (name + (off ? "_off" : "" ))
    "/images/newdesign/#{button_name}" 
  end
  
  def button_path_static(name, opts = {})
    button_name = "/images/#{name}.jpg" 
  end
  
  def staticbutton(name, opts = {})
    image_tag(button_path_static(name, opts), :id=>"meeting", :border => 0,:onmouseover=>"this.src= '/images/#{name}-over.jpg';",:onmouseout=>"this.src = '/images/#{name}.jpg';")
  end
  
  #Created By Amit Date:18 Sep
  def ibuttonhome(name, opts = { })
    image_submit_tag(button_path(name, opts), :id=>"signin",:class=>"signin",:src=>"/images/meetingwave/buttons/sign-in.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/sign-in-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/sign-in.gif';") 
  end
  
  def ibutton_change_location(name, opts = { })
    image_submit_tag(button_path(name, opts), :id=>"change",:class=>"signin",:src=>"/images/meetingwave/buttons/save.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/save-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/save.gif';",:align => "absmiddle") 
  end
  
  def ibutton_verify(name, opts = { })
    image_submit_tag(button_path(name, opts), :id=>"change",:class=>"signin",:src=>"/images/meetingwave/buttons/verify.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/verify-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/verify.gif';",:align => "absmiddle") 
  end
  
  def ibutton_change_forward(name,meeting, opts = { })
    image_submit_tag(button_path(name, opts),:align => "absmiddle", :id=>"forward",:class=>"signin",:src=>"/images/newdesign/forward.jpg",:onmouseover=>"this.src= '/images/newdesign/forward-over.jpg';",:onmouseout=>"this.src = '/images/newdesign/forward.jpg';", :onclick => " return hidden_values(#{meeting});") 
  end
  
  def ibuttonsign(name, opts = { })
    image_submit_tag(button_path(name, opts), :id=>"joinnow",:src=>"/images/meetingwave/buttons/join-now-meetingwave.jpg",:onmouseover=>"this.src= '/images/meetingwave/buttons/join-now-over-meetingwave.jpg';",:onmouseout=>"this.src = '/images/meetingwave/buttons/join-now-meetingwave.jpg';") 
  end  
  
  def ibuttonhomemeeting(name, opts = { })
    image_submit_tag(button_path(name, opts), :src=>"/images/meetingwave/buttons/find-meeting.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/find-meeting-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/find-meeting.gif';") 
  end
  
  def ibuttonhomemeeting_tag(name, opts = { })
    image_tag(button_path(name, opts), :src=>"/images/meetingwave/buttons/find-meeting.gif",:onmouseover=>"this.src= '/images/meetingwave/buttons/find-meeting-over.gif';",:onmouseout=>"this.src = '/images/meetingwave/buttons/find-meeting.gif';",:onclick => "window.location='/member'") 
  end  
	   
  def send_submit()
    ibutton('send', :class => 'send_button')
  end

  def logo
    content_tag('div', link_to(image_tag('/images/meetingwave/logo.gif'), home_url), :id => 'logo')
  end

  def search_results_title
    if( params[:action] == "area_search" )
         "<h1>#{params[:area]} Business Networking Meetings</h1>"
    else
      "Search Results"
    end
  end
 
  def metro_area_list(areas) 
    result = ""
    areas.sort.each_slice(6) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true))
      end
      result << content_tag('ul', inner_result, :class => 'metro_area_column') 
    end
    result
  end
  
  
  def metro_area_list_home(areas) 
    result = ""
    areas.sort.each_slice(6) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true), :class=>"country")
      end
      result << content_tag('ul', inner_result) 
    end
    result
  end
  
  
  def metro_area_list_home2(areas) 
    result = ""
    areas.sort.each_slice(6) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
	  	if area != "Phoenix"
	        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true), :class=>"country")
		end
      end
      result << content_tag('ul', inner_result) 
    end
    result
  end
  
  def metro_area_list_home3(areas) 
    result = ""
    areas.sort.each_slice(5) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true), :class=>"country")
      end
      result << content_tag('ul', inner_result) 
    end
    result
  end
  
  
  
  def metro_area_list_seeall(areas) 
    result = ""
    areas.sort.each_slice(3) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true),:style=>"padding: 10px;")
      end
      result << content_tag('ul', inner_result, :class => 'metro_area_column') 
    end
    result
  end
  
  def meeting_list(areas) 
    result = ""
    areas.sort.each_slice(6) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true),:style=>"padding: 10px;")
      end
      result << content_tag('ul', inner_result, :class => 'metro_area_column') 
    end
    result
  end  
  
  
  def meeting_today_list(areas) 
    result = ""
    areas.sort.each_slice(6) do |five_areas|
      inner_result = ""
      five_areas.each do |area|
        inner_result << content_tag('li', link_to(area , "/#{area}-Business-Networking-Meetings", :follow => true),:style=>"padding: 10px;")
      end
      result << content_tag('ul', inner_result, :class => 'metro_area_column') 
    end
    result
  end
  
  
  

  def mw_country_select(object, method, priority_countries = nil, options = {}, html_options = {})
	  obj = instance_variable_get("@#{object}")
	  value = obj.send(method)
	  main_opts = options_for_select(Country::COUNTRY_NAMES, value)
	  unless priority_countries.blank?
		  divider = content_tag("option", "-------------", :value => "", :disabled => "disabled")
		  priority_opts = options_for_select(priority_countries, value)
		  main_opts = priority_opts + divider + main_opts
	  end

	  if options[:include_blank]
		main_opts = "<option value=\"\">#{options[:include_blank] if options[:include_blank].kind_of?(String)}</option>\n" + main_opts
      end

	  if value.blank? && options[:prompt]
		main_opts = ("<option value=\"\">#{options[:prompt].kind_of?(String) ? options[:prompt] : 'Please select'}</option>\n") + main_opts
	  end
	  html_options.merge!(:id => "#{object}_#{method}", :name => "#{object}[#{method}]")
	  content_tag("select", main_opts, html_options)
  end
  
  def mw_country_home(object, method, priority_countries = nil, options = {}, html_options = {})
	  obj = instance_variable_get("@#{object}")
	  value = obj.send(method)
	  main_opts = options_for_select(Country::COUNTRY_NAMES, value)
	  unless priority_countries.blank?
		  #divider = content_tag("option", "-------------", :value => "", :disabled => "disabled")
		  priority_opts = options_for_select(priority_countries, value)
		  main_opts = priority_opts + main_opts
	  end

	  if options[:include_blank]
		main_opts = "<option value='United States'>-Select Outside US Countries-</option>\n" + main_opts
      end

	  if value.blank? && options[:prompt]
		main_opts = ("<option value='United States'>-Select Outside US Countries-</option>\n") + main_opts
	  end
	  html_options.merge!(:id => "#{object}_#{method}", :name => "#{object}[#{method}]")
	  content_tag("select", main_opts, html_options)
  end
  
  def facebook_connect_on_nav
   
     result = fb_connect_javascript_tag
     result += ( "\n" + init_fb_connect("XFBML")   + "\n")

     link = <<EOL
     
    <a href="#" id="connect_with_facebook_nav"
      onclick="FB.Connect.requireSession( function(){ window.location.href  = 'http://#{request.host_with_port}' ;}); return false;" >
      
      <img id="fb_login_image" src="/images/meetingwave/buttons/connect_with_facebook_gr.gif" alt="Connect"/> </a>
EOL
    result += link
    
  end 
  
  #~ def facebook_connect_on_nav_new
   
     #~ result = fb_connect_javascript_tag
     #~ result += ( "\n" + init_fb_connect("XFBML")   + "\n")

     #~ link = <<EOL
     
    #~ <a href="#" id="connect_with_facebook_nav"
      #~ onclick="document.getElementById('member_terms_of_service').checked='true'; FB.Connect.requireSession( function(){ window.location.href  = 'http://#{request.host_with_port}' ;}); return false;" >
      
      #~ <img id="fb_login_image" src="/images/connect_with_facebook_gr1.jpg" alt="Connect with Facebook" name="Connect with Facebook"  width="171" height="21" border="0"/> </a>
#~ EOL
    #~ result += link
    
  #~ end 

def facebook_connect_on_nav_new
     result = fb_connect_javascript_tag
     result += ( "\n" + init_fb_connect("XFBML")   + "\n")
     link = <<EOL
     
    <a href="#" id="connect_with_facebook_nav"
      onclick="document.getElementById('member_terms_of_service').checked='true'; FB.Connect.requireSession( function(){ window.location.href  = 'http://#{request.host_with_port}' ;}); return false;" >
      
      <img id="fb_login_image" src="/images/connect_with_facebook_gr1.jpg" style=">margin-left:405px;" alt="Connect with Facebook" name="Connect with Facebook"  width="171" height="21" border="0"/> </a>
EOL
    result += link
  end 
  
    def post_invite_message
      
      Facebooker::Session.runner_mode = true
      begin
        FacebookerFeedPublisher.register_post_invite unless Facebooker::Rails::Publisher::FacebookTemplate.find(:first , :conditions => "template_name like '%post_invite%'")
      ensure
        Facebooker::Session.runner_mode = false
      end
     
      if(@invitation || params[:invitation_id] )
           @invitation ||= Invitation.find(params[:invitation_id])
      template_data = {:image_link => link_to(image_tag("fb/announce_75.gif?v6", :style => "margin:3px;"), url_for( :controller => "facebook", :action => "index",  :canvas => true, :only_path => false)) ,
        :link => "#{link_to(@invitation.name, show_invite_url(:id => @invitation, :canvas => false, :only_path => false, :post_invite_news => true))}",
        :description => @invitation.description   }
   
        "FB.Connect.showFeedDialog(#{Facebooker::Rails::Publisher::FacebookTemplate.find(:first, :conditions => "template_name like '%post_invite'").bundle_id}, #{ template_data.to_json })"
      end
   end
  
  def facebook_connect_on_homepage
   
    result =  fb_connect_javascript_tag
    

    result <<  init_fb_connect("XFBML")

    link =  <<EOL
    
    
	
	<ul id="navbarfacebook">
	<li id="navbarfacebook-facebook">
	<a href="#" onclick="FB.Connect.requireSession( function(){ window.location.href  = 'http://#{request.host_with_port} ' ;}); document.getElementById('light').style.display='none';document.getElementById('fade').style.display='none';return false;" ><span>Facebook</span></a>
	  </li>
    </ul>
	
	
	
	
	
	
	
EOL
    result += link
  end
  
   def button_path_search(name, opts = {})
    off = opts.delete(:off)

    button_name =  (name + (off ? "_off" : "" ) + ".jpg")
	 "/images/newdesign/search_images/#{button_name}" 
  end
 
 
       
  def off_button_path_search(name)
    button_path_search(name , :off => true)
  end
       
  def button_image_search(name, opts = {})
    image_tag(button_path_search(name), opts)
  end
 
 
  
  
  
end
