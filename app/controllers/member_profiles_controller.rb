class MemberProfilesController < ApplicationController
  before_filter :private_global
  before_filter :url_check
  before_filter :login_required, :except => [ :show, :profile_not_found, :widget ]

  before_filter :get_instance_variables, :only => [ :update_external_profiles,
    :update_meeting_interests,
    :add_meeting_interest,
    :delete_meeting_interest,
    :update_job,
    :add_job,
    :delete_job,
    :update_personal_interests,
    :update_interests,
    :update_education,
    :add_education,
    :delete_education,
    :add_new_profile_widget,
    :populate_new_profile_widget,
    :finalize_new_profile_widget,
    :move_widget, 
    :delete_widget,
    :add_new_profile_widget_html,
    :update_profile_widget_html,
    :update_profile_section, 
    :add_profile_section,
    :delete_profile_section ]
  
  layout  "profile"  


  ##########################################
  #
  #  Caching stuff.
  ##########################################

  # These seem to be broken now with the new welcome_box
  #caches_action :edit
  #caches_action :show

  # Results in the mobile version being cached sometimes, which looks wrong.
  # caches_page :show
  
  after_filter :expire_cache_on_post 

  caches_action :widget

  def compute_cache_key(options = {}) 
    return nil if request.post?
    super(cache_key_param_hash)
  end  
	
  def cache_key_param_hash     
		  
    case params[:action]
    when 'edit'
      {:action => :edit, :controller => params[:controller], :member => current_member.id}
    when 'show'
      {'action' => :show, 'controller' => params[:controller], 'id' => params[:id], 'username' => params[:username],
        'context' => (params[:context].to_s rescue ""), 'format' => (params[:format].to_s rescue "")} 
    when 'widget' 
      response.time_to_live = 1.hours
      params
    end	   
  end
	
  def expire_cache_on_post
    if(request.post?)
      CachingObserver.clean_for_user(current_member)
    end
  end

  
  def index
    list
    render :action => 'list'
  end

  def profile_not_found 
    render :layout => 'static'
  end
  
  def show
    if params[:username]
      @member = Member.find_by_user_name(params[:username])
    else
      @member = Member.find_by_user_name(params[:id])
      if @member.nil?
        @member = Member.find(params[:id])
      end
    end

    if @member.nil?
      redirect_to "/campaigns"
      return
    end

    if @member.member_profile.nil?
      @member.create_member_profile 
      @member.reload  # get the new MP
    end

    check_render_facebook()   
  end
  
  def email_settings
    @me = current_member.member_emails
    @primary = @me.map{|x| x.primary}
  end
  
  def add_email
    texvalarr = params[:txtvalue].split(',')
    @arr = []
    texvalarr.each_with_index do |val,i|
      val = val.gsub(' ','')
      if val =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
        me = MemberEmail.new()
        me.member_id = current_member.id
        me.email = val
        me.save
        MemberNotify.deliver_domain_email_verification(request.host,me)
      else
        @arr << val
      end
    end     
    @me = current_member.member_emails
    @primary = @me.map{|x| x.primary}
    render :update do |page|
      page.replace_html "email_display", :partial => 'email_display'
      page.visual_effect :highlight,"email_display"
      page.replace_html "errdisplay", :partial => 'errdisplay'
      page.visual_effect :highlight,"errdisplay"
    end
  end
  
  def display_domain
    if params[:display] == "yes"
      if MemberEmail.find(params[:id]).verified == true
        MemberEmail.connection.execute("update member_emails set domain_display = 1 where id = #{params[:id]}")
      else
        @msg = "Your selected email address is not verified yet."
      end
    else
      MemberEmail.connection.execute("update member_emails set domain_display = 0 where id = #{params[:id]}")
    end
    @me = current_member.member_emails
    @primary = @me.map{|x| x.primary}
    render :update do |page|
      page.replace_html "email_display", :partial => 'email_display'
      page.replace_html "msgdisplay", :partial => 'msgdisplay' if @msg
      page.visual_effect(:fade,"msgdisplay", :duration => 5) if @msg
    end
  end
  
  def make_primary
    if params[:imagevalue] == "make-primary"
      if !params[:primary].blank?
        if MemberEmail.find(params[:primary]).verified == true
          current_member.member_emails.each do |primary|
            if primary.primary == true
              MemberEmail.connection.execute("update member_emails set `primary` = 0 where id = #{primary.id}")
            end
          end
          
          MemberEmail.connection.execute("update member_emails set `primary` = 1 where id = #{params[:primary].to_i}")
          Member.connection.execute("update members set has_primary = 1 where id = #{current_member.id}")
          @msg = "Your Primary Email Address has been changed."
        else
          @msg = "Your selected email address is not verified yet."
        end
      else
        current_member.member_emails.each do |primary|
          if primary.primary == true
            MemberEmail.connection.execute("update member_emails set `primary` = 0 where id = #{primary.id}")
          end
          @msg = "Your Primary Email Address has been changed."
        end
      end
    elsif params[:imagevalue] == "remove"
      if !params[:primary].blank?
        MemberEmail.find(params[:primary]).delete
        Member.connection.execute("update members set has_primary = 0 where id = #{current_member.id}")
        @msg = "Your selected email address has been removed."
      else
        @msg = "Your can not removed your default email address."
      end
    elsif params[:imagevalue] == "send-conf" 
      me = MemberEmail.find(params[:primary])
      MemberNotify.deliver_domain_email_verification(request.host,me)
      @msg = "A confirmation email has been sent to your email."
    end
    @me = MemberEmail.find(:all,:conditions => ["member_id = ?",current_member.id])
    @primary = @me.map{|x| x.primary}
    render :update do |page|
      page.replace_html "email_display", :partial => 'email_display',:locals => {:me => @me,:primary => @primary}
      page.replace_html "msgdisplay", :partial => 'msgdisplay'
      page.visual_effect(:fade,"msgdisplay", :duration => 5)
    end
  end
  
  #~ def show
    #~ eve =  Member.find_by_id(params[:id]) if params[:id]
    #~ eve =  Member.find_by_id(params[:id]) if params[:username]
    
    #~ puts"====================================="
    #~ puts eve.inspect
    
    #~ if eve.university_name == 'public'
      #~ if params[:username]
        #~ @member = Member.find_by_user_name(params[:username])
      #~ else
        #~ @member = Member.find_by_user_name(params[:id])
        #~ if @member.nil?
          #~ @member = Member.find(params[:id])
        #~ end
      #~ end

      #~ if @member.nil?
        #~ redirect_to member_profile_not_found_url
        #~ return
      #~ end

      #~ if @member.member_profile.nil?
        #~ @member.create_member_profile 
        #~ @member.reload  # get the new MP
      #~ end

      #~ check_render_facebook()   
    #~ else
      #~ if current_member and current_member.university_name == eve.university_name
        #~ if params[:username]
          #~ @member = Member.find_by_user_name(params[:username])
        #~ else
          #~ @member = Member.find_by_user_name(params[:id])
          #~ if @member.nil?
            #~ @member = Member.find(params[:id])
          #~ end
        #~ end

        #~ if @member.nil?
          #~ redirect_to member_profile_not_found_url
          #~ return
        #~ end

        #~ if @member.member_profile.nil?
          #~ @member.create_member_profile 
          #~ @member.reload  # get the new MP
        #~ end

        #~ check_render_facebook()   
      #~ else
        #~ redirect_to "http://#{eve.university_name}.#{request.host}/member" if !request.host.match(eve.university_name)
        #~ redirect_to "http://#{request.host}/member" if request.host.match(eve.university_name)
      #~ end
    #~ end
  #~ end
  
  #~ def show

  #~ end

  def edit
    member?
    @member = current_member
    @member = Member.find(@member.id, :include => [{:member_profile => MemberProfile::EAGER_LOADING_CANDIDATES}])
    @invites = @member.public_profile_posted_invites(@univ_account,4).reverse
    if @member.member_profile.nil?
      @member.create_member_profile 
      @member.reload  # get the new MP
    end

    @profile_widgets = @member.member_profile.profile_widgets
    @column_a_widgets = @member.member_profile.profile_widgets.find(:all, :conditions => [ ' col = "A"'], :order => 'row')
    @column_b_widgets = @member.member_profile.profile_widgets.find(:all, :conditions => [ ' col = "B"'], :order => 'row')
   
    offset = params[:client_tz_offset] || '-18000'
    tz = TimeZone.mw_us_zones.find { |z| z.utc_offset == offset.to_i } 
    tz ||= TimeZone[offset.to_i]

    @member.member_profile ||= MemberProfile.new( :time_zone => tz.name )
    @member_profile = @member.member_profile 
    @member_profile.valid?
    check_render_facebook(:profile, :edit)   
    return unless request.post?
    
    @member_profile.attributes = params[:member_profile]
    if @member_profile.save
      flash.now[:notice] = 'Your profile was successfully updated.'
    end
    
  end
  MAX_ID_FOR_FAKEY_IMPORT = 20000000
  def import_facebook_profile
    member?
    @member = current_member
    if(@member.member_profile && @member.member_profile.filled_in?)
      edit
      return 
    end
    @member = Member.find(@member.id, :include => [{:member_profile => MemberProfile::EAGER_LOADING_CANDIDATES}])
    @invites = @member.public_posted_invites(4).reverse
    if @member.member_profile.nil?
      @member.create_member_profile 
      @member.reload  # get the new MP
    end

    @profile_widgets = @member.member_profile.profile_widgets
    @column_a_widgets = @member.member_profile.profile_widgets.find(:all, :conditions => [ ' col = "A"'], :order => 'row')
    @column_b_widgets = @member.member_profile.profile_widgets.find(:all, :conditions => [ ' col = "B"'], :order => 'row')
   
    offset = params[:client_tz_offset] || '-18000'
    tz = TimeZone.mw_us_zones.find { |z| z.utc_offset == offset.to_i } 
    tz ||= TimeZone[offset.to_i]

    @member.member_profile ||= MemberProfile.new( :time_zone => tz.name )
    @member_profile = @member.member_profile 
    @member_profile.valid?
   
    @educations = []
    if @member_profile.educations.blank?
      @educations = current_member.social_network_user.educations
      @educations.each_with_index{|education,index| education.id = MAX_ID_FOR_FAKEY_IMPORT + index }
    end
    
    @jobs = []
    if( @member_profile.jobs.blank?)
      @jobs = current_member.social_network_user.jobs
      @jobs.each_with_index{|job,index| job.id = MAX_ID_FOR_FAKEY_IMPORT + index }
    end
    MemberProfile::ATTRS_BY_TYPE[:personal].each do |personal_attr|
      @member_profile.send("#{personal_attr}=", (current_member.social_network_user.send(personal_attr) rescue nil ) )
    end
    
    render :layout => "profile_fbml"
  end
  
  def update_external_profiles
    params[:external_profile_links].each_with_index do |lnk, idx|
      if @member_profile.external_profiles.blank? or @member_profile.external_profiles[idx].blank?
        @member_profile.external_profiles << ExternalProfile.create(:link => lnk)
      else
        @member_profile.external_profiles[idx].link = lnk
        @member_profile.external_profiles[idx].save
      end
    end
    
    if request.xhr?  
      render :update do |page| 
        page.replace 'external_profile_links_container', :partial => 'external_profile_links', 
          :locals => { :member => @member, :member_profile => @member.member_profile }
      end
    else
      redirect_to :action => :edit
    end
  
  end
  
  # MEETING INTERESTS
  def update_meeting_interests
    @meeting_interest = @member_profile.meeting_interests.find(params[:meeting_interest][:id])
    @meeting_interest.attributes = params[:meeting_interest]
    @saved = @meeting_interest.save
    @profile_widget = @member_profile.meeting_interests_widget
    @replace_div = "meeting_interests_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div, :partial => 'meeting_interests_widget', 
        :locals => { :member_profile => @member_profile, 
        :new_meeting_interest => @new_meeting_interest, 
        :profile_widget => @profile_widget }   
    end
  end
  def add_meeting_interest
    @new_meeting_interest = MeetingInterest.new(:member_profile => @member_profile)
    @new_meeting_interest.attributes = params[:new_meeting_interest]
    @saved = @new_meeting_interest.save
    @profile_widget = @member_profile.meeting_interests_widget
    @replace_div = "meeting_interests_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'meeting_interests_widget', 
        :locals => { :member_profile => @member_profile, 
        :new_meeting_interest => (@saved ? nil : @new_meeting_interest),
        :profile_widget => @profile_widget }
    end
  end
  def delete_meeting_interest  
    @meeting_interest = @member_profile.meeting_interests.find(params[:id])
    @meeting_interest.destroy
    render :update do |page|
      page.remove "edit_subsection_meeting_interest_#{@meeting_interest.id}"
      page.remove "view_subsection_meeting_interest_#{@meeting_interest.id}"
    end
  end

  # JOBS
  def update_job  
    @job = @member_profile.jobs.find(params[:job][:id])  
    @job.attributes = params[:job]
    @saved = @job.save
    @profile_widget = @member_profile.employment_widget
    @replace_div = "jobs_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'employment_widget', 
        :locals => { :member_profile => @member_profile, 
        :new_job => (@saved ? nil : @new_job),
        :profile_widget => @profile_widget }
    end
  end  
  def add_job
    @new_job = Job.new(:member_profile => @member_profile)
    @new_job.attributes = params[:new_job]
    @saved = @new_job.save
    @profile_widget = @member_profile.employment_widget
    @replace_div = "jobs_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'employment_widget', 
        :locals => { :member_profile => @member_profile, 
        :new_job => (@saved ? nil : @new_job),
        :profile_widget => @profile_widget }
    end
  end
  
  def delete_job
    @job = @member_profile.jobs.find(params[:id])
    @job.destroy
    render :update do |page| 
      page.remove "edit_subsection_job_#{@job.id}"
      page.remove "view_subsection_job_#{@job.id}"
    end
  end
  
  # PERSONAL INTERESTS
  def update_personal_interests
    @member_profile.attributes = params[:member_profile]
    @member_profile.save
    @profile_widget = @member_profile.personal_interests_widget
    @replace_div = "personal_interests_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'personal_widget', 
        :locals => { :member_profile => @member_profile,
        :profile_widget => @profile_widget }
    end
  end
  
  def update_interests
    @member_profile.attributes = params[:member_profile]
    @member_profile.save
  end
  
  # EDUCATIONS
  def update_education
    @education = @member_profile.educations.find(params[:education][:id])  
    @education.attributes = params[:education]
    @saved = @education.save
    @profile_widget = @member_profile.educations_widget
    @replace_div = "educations_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'educations_widget', 
        :locals => { :member_profile => @member_profile, 
        :new_education => (@saved ? nil : @new_education),
        :profile_widget => @profile_widget }
    end
  end  
   
  def add_education
    @new_education = Education.new(:member_profile => @member_profile)
    @new_education.attributes = params[:new_education]
    @saved = @new_education.save
    @profile_widget = @member_profile.educations_widget
    @replace_div = "educations_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'educations_widget', 
        :locals => { :member_profile => @member_profile, 
        :new_education => (@saved ? nil : @new_education),
        :profile_widget => @profile_widget }
    end
  end
   
  def import_education
    import_thing("education")
  end
   
  def import_job
    import_thing("job")
  end
   
  def import_thing(thing)
    @member_profile = current_member.member_profile
    thing_symbol = thing.to_sym
       
    @thing = thing.capitalize.constantize.new(:member_profile => @member_profile)
    fake_id = params[thing_symbol].delete(:id)
    @thing.attributes = params[thing_symbol]
    @saved = @thing.save
    # replace the view portion and show it and hide the edit box.
    @view_div = "view_subsection_#{thing}_#{fake_id}"
    @edit_div = "edit_subsection_#{thing}_#{fake_id}"
       
    render :update do |page|
      page.replace_html(@view_div, :partial => "#{thing}_view_subsection", :locals => {thing_symbol => @thing})
      page.show(@view_div)
      page.replace(@edit_div, :text  => "")
    end   
     
  end
   
  def delete_education
    @education = @member_profile.educations.find(params[:id])
    attribute_name = @education.school_type.gsub(" ", "_").downcase.pluralize.to_sym 
    @education.destroy
    delete_header = @member_profile.send(attribute_name).blank?
    logger.error("attribute_name: #{attribute_name}")
    render :update do |page|
      page.remove "edit_subsection_education_#{@education.id}"
      page.remove "view_subsection_education_#{@education.id}"
      if delete_header
        page.remove(attribute_name) 
        page.remove("#{attribute_name}-edit") 
      end
    end
  end
  
  def profile_widget
    render :layout => false
  end
  
  # ADD NEW PROFILE WIDGET
  def add_new_profile_widget
    @new_profile_widget = ProfileWidget.new(:member_profile => @member_profile, :title => params[:new_profile_widget][:title])
    @new_profile_widget.save
    render :update do |page| 
      page.replace :new_profile_widget, :partial => 'populate_widget'
    end
  end
  
  def populate_new_profile_widget
    @profile_widget = ProfileWidget.find(params[:profile_widget][:id])
    @profile_section = ProfileSection.create(:profile_widget => @profile_widget, :member_profile => @member_profile, :name => params[:new_profile_section][:name])
    params[:new_section_details][:text].each do |detail|
      SectionDetail.create(:profile_section => @profile_section, :text => detail)
    end
    render :update do |page|
      page.replace :new_profile_widget, :partial => 'continue_to_populate_widget'
    end
  end
  
  def finalize_new_profile_widget
    @profile_widget = ProfileWidget.find(params[:profile_widget][:id])
    unless (params[:new_profile_section][:name].blank? or params[:new_section_details][:text].blank?)
      @profile_section = ProfileSection.create(:profile_widget => @profile_widget, :member_profile => @member_profile, :name => params[:new_profile_section][:name])
      params[:new_section_details][:text].each do |detail|
        SectionDetail.create(:profile_section => @profile_section, :text => detail)
      end
    end  
    @profile_widget.col = 'B'
    @profile_widget.row = 1
    @profile_widget.save
    render :update do |page|
      page.replace 'new_profile_widget', :partial => 'create_widget'
      page.insert_html :top, 'column_B', :partial => 'user_widget', :locals => {:profile_widget => @profile_widget}
      page.call 'Sortable.create("column_B", {constraint:false, containment:["column_A","column_B"], dropOnEmpty:true, handle:"movable", onUpdate:function(){new Ajax.Request("/member_profiles/move_widget/B", {asynchronous:true, evalScripts:true, parameters:Sortable.serialize("column_B")})}, tag:"div"})'
      page.call 'Sortable.create("column_A", {constraint:false, containment:["column_A","column_B"], dropOnEmpty:true, handle:"movable", onUpdate:function(){new Ajax.Request("/member_profiles/move_widget/A", {asynchronous:true, evalScripts:true, parameters:Sortable.serialize("column_A")})}, tag:"div"})'
    end  
  end  

  def update_profile_section
    @profile_section = ProfileSection.find(params[:profile_section][:id])
    @profile_widget = @member_profile.profile_widgets.find(@profile_section.profile_widget_id)
    @profile_section.attributes = params[:profile_section]

    params[:section_detail].each do |section_detail_id, section_detail_attrs|
      section_detail = @profile_section.section_details.find(section_detail_id)
      if section_detail_attrs[:text].blank?
        section_detail.destroy
      else
        section_detail.text = section_detail_attrs[:text]
        section_detail.save
      end
    end
     
    @replace_div = "user_widget_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'user_widget', 
        :locals => { :member_profile => @member_profile, 
        :profile_widget => @profile_widget }
    end
  end


  def add_profile_section
    @profile_widget = @member_profile.profile_widgets.find(params[:profile_widget][:id])
    @profile_section = ProfileSection.new(:profile_widget => @profile_widget, :name => params[:new_profile_section][:name])
    @saved = @profile_section.save
    params[:new_section_details][:text].each do |text|
      SectionDetail.create(:text => text, :profile_section => @profile_section) unless text.blank?
    end
    @replace_div = "user_widget_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'user_widget', 
        :locals => { :member_profile => @member_profile, 
        :profile_widget => @profile_widget, 
        :new_profile_section => (@saved ? nil : @profile_section) }
    end
  end

  def delete_profile_section
    @profile_section = ProfileSection.find(params[:id])
    @profile_widget = @profile_section.profile_widget
    if @profile_widget.member_profile == @member_profile
      @profile_section.destroy
    end
    @replace_div = "user_widget_#{@profile_widget.id}"
    render :update do |page| 
      page.replace @replace_div,  
        :partial => 'user_widget', 
        :locals => { :member_profile => @member_profile, 
        :profile_widget => @profile_widget }
    end

    
  end
  
  def delete_widget
    @profile_widget = @member_profile.profile_widgets.find(params[:id])
    @profile_widget.destroy
    render :update do |page|
      page.remove "user_widget_#{@profile_widget.id}"
    end
  end
  
  # We reload when updating or adding HTML widgets because a lot of them rely on page-loads.  For instance, any 
  # badge or widget-box from an external site is going to load some .js from the external server via a script tag.
  def add_new_profile_widget_html
    @new_profile_widget = ProfileWidget.new(:member_profile => @member_profile, 
      :title => params[:new_profile_widget][:title],
      :html => params[:new_profile_widget][:html], 
      :col => 'B', :row => 1, :widget_partial => 'html')
    @new_profile_widget.save
    redirect_to :action => :edit
  end
  
  def update_profile_widget_html
    @profile_widget = ProfileWidget.find(params[:profile_widget][:id])
    @profile_widget.attributes = {:title => params[:profile_widget][:title],
      :html => params[:profile_widget][:html] }
    @profile_widget.save
    redirect_to :action => :edit
  end
  
  def move_widget
    col = params[:col]
    widget_ids = params["column_#{col}"]
    if(widget_ids)
      widget_ids.each_with_index do |widget_id, row|
        profile_widget = ProfileWidget.find_by_id_and_member_profile_id(widget_id, @member_profile.id)
        profile_widget.attributes = { :col => col, :row => row }
        profile_widget.save
      end
    end
    render :update do |page| 
      page.replace_html(:flash, :text => "Your profile page has been updated.")
    end
  end
  
  def widget
    settings
    limit = @settings[:limit].to_i    
    @invites = Member.find_by_uuid(params[:uuid]).invitations.reject(&:deactivated?).select(&:next_occurrence).sort_by(&:next_occurrence).reverse[0...limit].reverse
    response.time_to_live = 1.day
    render :partial => 'widget' , :layout => 'widget' unless params[:format] == "mp"
  end
  

  def widget_config
    settings
    render :layout => 'widget_config'
  end  

  def color_test

  end


  private

  def settings
    @settings = {
      :background => "fcfcfc",
      :size => "9",
      :size_name => "small",
      :even_color => "FCFCFC",
      :odd_color => "FCFCFC" ,
      :logo_background => "FFFFFF" ,
      :tag_color => "42412D",
      :font_color => "42412D",
      :description_color => "42412D",      
      :date_color => "80807a",      
      :link_color => "4977B8",
      :hover_color => "D47D20",
      :sm_color => "939364" ,  
      :limit => "5",
      :name => "My Invites",
      :uuid => (current_member.uuid rescue nil)
        
    }

    @sizes_to_widths = { 'small' => '220px',
      'medium' => '240px',
      'large' => '260px'} 
    @sizes_to_logos = { 'small' => {:height => 55, :width => 220},
      'medium' => {:height => 60, :width => 240},
      'large' => {:height => 70, :width =>  260}
    }

    @settings.each do |k,v|
      @settings[k] = params[k] if params[k]
    end

  end

  
  def get_instance_variables
    @member = current_member
    @member_profile = @member.member_profile
  end
    
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
    end
  end
  
end
