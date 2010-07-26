require 'invite_utilities'
class PostInviteController < ApplicationController
 include InviteUtilities   
 include TTB::FacebookCanvasHelper
 before_filter :url_check

 layout 'editor'
 helper :invitations
 before_filter :login_required

 def new
  @invitation = @viewer.invitations.build
  @address = Address.new(:kind => 'regular')
  @invitation.address = @address
  # By default, we assume eastern.  Better than the regular default (Hawaii) and
  # less error-prone than trying to guess based on browser, member_profile, etc.
  @invitation.time_zone = 'Eastern Time (US & Canada)'
  @email_addresses = @invitation.invited_non_members.collect { |nm| nm.email }

  @members = @invitation.invited_members
  @member_ids = @invitation.invited_members.collect{ |m| m.id.to_s }     

  check_render_facebook()
  return
end


 ## We made a new function for the new create a meeting page.
 def new_create
  @member_profile = current_member.member_profile
  @invitation = @viewer.invitations.build
  @address = Address.new(:kind => 'regular')
  @invitation.address = @address
  # By default, we assume eastern.  Better than the regular default (Hawaii) and
  # less error-prone than trying to guess based on browser, member_profile, etc.
  @invitation.time_zone = 'Eastern Time (US & Canada)'
  @email_addresses = @invitation.invited_non_members.collect { |nm| nm.email }
  @members = @invitation.invited_members
  @member_ids = @invitation.invited_members.collect{ |m| m.id.to_s }     
  check_render_facebook()
     render :layout => 'new_editor'
  return
end

  def state_country_toggle
    @address = Address.new(:kind => 'regular')
    render :update do |page|
      if params[:change] == "1"
        page.replace_html "sctoggle", :partial => 'post_invite/inside_us_link'
        page.replace_html "stat", :partial => 'post_invite/countries'
      else
        page.replace_html "sctoggle", :partial => 'post_invite/outside_us_link'
        page.replace_html "stat", :partial => 'post_invite/states'
      end  
    end
  end
  
  def state_country_toggle_new
    @address = Address.find(params[:id])
    render :update do |page|
      if params[:change] == "1"
        page.replace_html "sctoggle_new", :partial => 'post_invite/inside_us_link_new'
        page.replace_html "stat_new", :partial => 'post_invite/countries'
      else
        page.replace_html "sctoggle_new", :partial => 'post_invite/outside_us_link_new'
        page.replace_html "stat_new", :partial => 'post_invite/states'
      end  
    end
  end  

  ## Function for making a hash of address parameters for different type of address after submit the location popup.
  def make_address_hash
    session[:add_h] = nil
    session[:yadd_h] = nil
    session[:undisclosed_address] = nil
    @add_hash = params[:address]
    session[:undisclosed_address] = params[:undisclosed_address_regular]
    puts params[:address].inspect
    session[:add_h] = Hash.new()
    session[:add_h] = params[:address]
    if params[:address][:kind] == "yelp"   ## yelp address hash.
      session[:yadd_h] = nil
      session[:yadd_h] = Hash.new()
      session[:yadd_h] = params[:yaddress]
    end
    
    if params[:address][:kind] == "saved"  ## saved address hash.
      if !params[:address][:id].nil?
        add = Address.find(params[:address][:id]) if params[:address][:id]
        add_hash = Hash.new
        add_hash = {:name => add.name,:city => add.city, :country => add.country, :address => add.address,:state => add.state,:zip => add.zip} if !add.nil?
      else
        add_hash = Hash.new
        add_hash = {:name => "Open",:city => current_member.member_profile.current_city, :country => current_member.member_profile.current_country,:state => current_member.member_profile.current_state}
      end
      session[:add_h] = session[:add_h].merge(add_hash)
    end
    
    if params[:open]  ## location not decided.
      if !params[:member_profile][:current_city].nil?
        @member_profile = current_member.member_profile	
        @member_profile.update_attributes(params[:member_profile])
        @member_profile.save
        add_hash = Hash.new
        add_hash = {:name => params[:open],:city => @member_profile.current_city, :country => @member_profile.current_country,:state => @member_profile.current_state}
        session[:add_h] = session[:add_h].merge(add_hash)
      else
        add_hash = Hash.new
        add_hash = {:name => params[:open],:city => params[:city1], :country => params[:country1],:state => params[:state1]}
        session[:add_h] = session[:add_h].merge(add_hash)
      end
    end    
    
    render :update do |page|
      @add_name = session[:add_h][:name] if session[:add_h] and session[:add_h][:name]
      @add_name = session[:add_h][:terminal_gate] if session[:add_h] and session[:add_h][:terminal_gate]
      @add_name = session[:yadd_h][:name] if session[:yadd_h] and session[:yadd_h][:name]
      page.replace_html "newid", :partial => 'post_invite/new_address_hash'
      page.visual_effect :highlight, 'newid'
    end
  end
  
  ## Function for choosing preference option on create a meeting page.
  def change_date_picker
    @invitation = @viewer.invitations.build   
    render :update do |page|
      if params[:change] == "1"
        page.replace_html "date_sel", :partial => 'invite_editor/preffered_day_time'
      elsif params[:change] == "2"
        page.replace_html "date_sel", :partial => 'invite_editor/exact_date_time'
      else
        page.replace_html "date_sel", :partial => 'invite_editor/no_preference'
      end
    end
  end
  
  ## Function for editing location from saved location section on edit location popup.
  def edit_saved_location
    @address = Address.find(params[:id])
    render :update do |page|
      page.replace_html "edit_saved_loc", :partial => 'post_invite/edit_saved_location'
    end
  end
  
  ## Function for editing location from saved location section on edit location popup.
  def update_address
    @address = Address.find(params[:address][:id])
    if @address.update_attributes(params[:address]) 
    else
      @address.errors.each_full do |msg|
        message1 = msg.gsub(/[\n]/,'<br>')
      end 
    end
    flash[:update_msg] = "Location Updated."
    render :update do |page|
      page.replace_html "new_saved_loc", :partial => 'post_invite/new_saved_location'
    end
  end

 ## We made a new function for saving meetings for new create a meeting page.
 def new_save  
  @member_profile = current_member.member_profile	
  @invitation = @viewer.invitations.build   
  params[:address] = session[:add_h]
  params[:yaddress] = session[:yadd_h]
  if !params[:address].nil?
    if params[:address][:kind] == "saved"
     if !params[:address][:id].nil?
       logger.error("trying to find address: #{params[:address][:id]}")
       @address = Address.find(params[:address][:id])
     else
       @address = Address.new(params[:address])
     end
    elsif params[:address][:kind] == "yelp"
     @address = Address.new(params[:yaddress])
     # We get a country code from Google, not the country name
     @address.country = Country::COUNTRIES[params[:yaddress][:country]]
     @address.kind = "regular"
     @address.save
    else
     params[:address] = fix_address_params(params)
     @address = get_address(params[:address].dup) || Address.new(params[:address])
     @address.save
    end
    @invitation.address = @address
  else
    @address = Address.new(:kind => 'regular')
  end 
  (@email_addresses, @member_ids) = params["who-auto-field"].split(",").partition{ |item|  item.to_s.include?("@") }
  @member_ids = params[:member_ids].keys.collect(&:to_s).uniq unless params[:member_ids].blank?    
  @email_addresses.each{ |e| e.strip! }
  if @member_ids.blank?
   @member_ids = [] 
   @members = []
  else
   @members = Member.find(@member_ids)
  end
  @email_addresses = [] if @email_addresses.blank?
  # This is a hack: in order to preserve the errors on start_time/end_time, we
  # have to add them to the model after validation occurs in .save below.
  time_date_errors = { }
 if params[:invitation][:start_time_local]
  @invitation.time_zone = params[:invitation][:time_zone]
  begin
   @invitation.start_time = Time.parse_with_timezone(params[:invitation][:start_time_local], params[:invitation][:time_zone])
  rescue InvalidTimeStringException => e
   logger.error "Error: #{$!} time_string was: #{params[:invitation][:start_time_local]} "
   time_date_errors[:start_time] = Invitation::EMPTY_TIME_DATE_MESSAGE
 end
 end


if params[:invitation][:end_time_local]
  begin
   @invitation.end_time = Time.parse_with_timezone(params[:invitation][:end_time_local], params[:invitation][:time_zone])
  rescue InvalidTimeStringException => e
   time_date_errors[:end_time] = Invitation::EMPTY_TIME_DATE_MESSAGE unless time_date_errors[:start_time]
  end
  [ :start_time_local, :end_time_local].map{ |pseudo_attribute| params[:invitation].delete(pseudo_attribute)  }
end
  # Finally, update the invite and its address
    #fix_undisclosed_address_bug() if !params[:address].nil? # Hack because of some weird checkbox issue during rails 2.3 upgrade.  

  @invitation.attributes = params[:invitation]
  if (params[:invitation][:purpose_id].to_i == Purpose::OTHER.id.to_i)
   @invitation.purpose = Purpose.new(:name => params[:other_purpose], :category => 'other')
  end
  
  if !params[:address].nil?
    unless (params[:address][:kind] == "saved" || params[:address][:kind] == 'yelp')
     @invitation.address.attributes = params[:address]
    end
  end

  if params[:v_type] == "on"
    @invitation.virtual_f = "v_flag"
    @invitation.virtual_type = params[:virtual_type]
  else
    @invitation.virtual_f = "no_flag"
  end
  
  @invitation.preference_flag = params[:preferred_time] if params[:preferred_time] == "1"
  
  @invitation.undisclosed_address = session[:undisclosed_address]

  # Let's see if it's valid
  valid = (@invitation.save && time_date_errors.empty? && @invitation.address.save) if !@invitation.address.nil? && (params[:v_type] == "on" or params[:loc_type] == "on")
  valid = (@invitation.save && time_date_errors.empty? ) if @invitation.address.nil? && (params[:v_type] == "on" or params[:loc_type] == "on")
  if @invitation.is_private? and @member_ids.blank? and @email_addresses.blank?
   @invitation.errors.add(:invited_members, "Private invites require at least one invitee.")
   valid = false
  end
  
  if(valid)     
    if params[:private_name] == "on"
      hidden_user = HiddenUserName.new
      hidden_user.invitation_id = @invitation.id
      hidden_user.private_name_flag = 1
      hidden_user.private_name = params[:uname]
      hidden_user.save
    end
    
     update_invitees(@invitation, @member_ids, @email_addresses)    

     new_members = @invitation.invited_and_unnotified_members
     new_non_members = @invitation.invited_and_unnotified_non_members

     existing_members = (@invitation.invited_and_notified_members + @invitation.confirmed_invitees).uniq
     existing_non_members = @invitation.invited_and_notified_non_members

     invite(@invitation, new_members)
     invite_non_members(@invitation, new_non_members)
     notify_inviter(@invitation)

     @invitation.step = 'Done'
     @invitation.draft_status = 'posted'
     @invitation.save

     flash[:notice] = "Your invitation has been successfully posted!  "
   
    session[:add_h] = nil
    session[:yadd_h] = nil
    session[:undisclosed_address] = nil
   
   flash[:fb_connect_post] = "true" if(current_member.social_network_user)

   if @invitation.invited_members.size > 0 or @invitation.invited_non_members.size > 0
    flash[:notice] <<   "Notifications have been sent to your invitees to let them know about this invite."
   end
   if(context?(:social_network))
    url = facebook_invite_friends_to_invite_url(:id => @invitation.id, :canvas => true, :only_path => false) #this has been changed on the routing level
    render :text => "<script> parent.location = '#{url}' </script> "
   elsif (mobile_request? or @viewer.member_profile.filled_in?)
    redirect_to show_invite_url(:id => @invitation.id)
   else
    redirect_to my_profile_url(:just => 'posted', :invitation_id => @invitation.id)
   end
  else
   time_date_errors.each { |attribute, error| @invitation.errors.add(attribute, error)}
   flash.now[:notice] = "Some errors prevented your invite from being posted.  Please correct the errors in each box below and hit Post Invite again."
   @address = @invitation.address
   if( context?(:social_network) )
    render_facebook_new()
   else
        @invitation.errors.each_full do |msg|
          logger.info "JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ"
          logger.info message1 = msg.gsub(/[\n]/,'<br>')
        end 
    flash.now[:location_error] = "Please select at least one location type." if params[:v_type].nil? && params[:loc_type].nil?
    @address = Address.new(:kind => 'regular')
    render :action => 'new_create',:layout => "new_editor"
   end
  end

 end

 def save                 
  logger.info "1111111111111111111111111111111111111111111"
  logger.info @viewer.inspect
  @invitation = @viewer.invitations.build
  logger.info @invitation.inspect
  logger.info "2222222222222222222222222222222222222222222"
  logger.info params[:invitation].inspect
  logger.info "3333333333333333333333333333333333333333333"
  logger.info params[:address].inspect
  if params[:address][:kind] == "saved"
   logger.info "4444444444444444444444444444444444444444444"
 
   logger.error("trying to find address: #{params[:address][:id]}")
   @address = Address.find(params[:address][:id])
  elsif params[:address][:kind] == "yelp"
      logger.info "55555555555555555555555555555555555555555"

   @address = Address.new(params[:yaddress])
   # We get a country code from Google, not the country name
   @address.country = Country::COUNTRIES[params[:yaddress][:country]]
   @address.kind = "regular"
   @address.save
  else
      logger.info "6666666666666666666666666666666666666666"

   params[:address] = fix_address_params(params)
   @address = get_address(params[:address].dup) || Address.new(params[:address])
   @address.save
 end
 
 logger.info "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK"
 logger.info @address.inspect
 
  @invitation.address = @address

  (@email_addresses, @member_ids) = params["who-auto-field"].split(",").partition{ |item|  item.to_s.include?("@") }

  @member_ids = params[:member_ids].keys.collect(&:to_s).uniq unless params[:member_ids].blank?    
  @email_addresses.each{ |e| e.strip! }
  if @member_ids.blank?
   @member_ids = [] 
   @members = []
  else
   @members = Member.find(@member_ids)
  end
  @email_addresses = [] if @email_addresses.blank?
 
  # This is a hack: in order to preserve the errors on start_time/end_time, we
  # have to add them to the model after validation occurs in .save below.
  time_date_errors = { }
  @invitation.time_zone = params[:invitation][:time_zone]
  begin
   @invitation.start_time = Time.parse_with_timezone(params[:invitation][:start_time_local], params[:invitation][:time_zone])
  rescue InvalidTimeStringException => e
   logger.error "Error: #{$!} time_string was: #{params[:invitation][:start_time_local]} "
   time_date_errors[:start_time] = Invitation::EMPTY_TIME_DATE_MESSAGE
  end

  begin
   @invitation.end_time = Time.parse_with_timezone(params[:invitation][:end_time_local], params[:invitation][:time_zone])
  rescue InvalidTimeStringException => e
   time_date_errors[:end_time] = Invitation::EMPTY_TIME_DATE_MESSAGE unless time_date_errors[:start_time]
  end
  [ :start_time_local, :end_time_local].map{ |pseudo_attribute| params[:invitation].delete(pseudo_attribute)  }

  # Finally, update the invite and its address
    fix_undisclosed_address_bug() # Hack because of some weird checkbox issue during rails 2.3 upgrade.  

  @invitation.attributes = params[:invitation]
  if (params[:invitation][:purpose_id].to_i == Purpose::OTHER.id.to_i)
   @invitation.purpose = Purpose.new(:name => params[:other_purpose], :category => 'other')
  end
  
  unless (params[:address][:kind] == "saved" || params[:address][:kind] == 'yelp')
   @invitation.address.attributes = params[:address]
  end

  # Let's see if it's valid
  valid = (@invitation.save && time_date_errors.empty? && @invitation.address.save)
  if @invitation.is_private? and @member_ids.blank? and @email_addresses.blank?
   @invitation.errors.add(:invited_members, "Private invites require at least one invitee.")
   valid = false
  end
  

  if(valid)     
   update_invitees(@invitation, @member_ids, @email_addresses)    

   new_members = @invitation.invited_and_unnotified_members
   new_non_members = @invitation.invited_and_unnotified_non_members

   existing_members = (@invitation.invited_and_notified_members + @invitation.confirmed_invitees).uniq
   existing_non_members = @invitation.invited_and_notified_non_members

   invite(@invitation, new_members)
   invite_non_members(@invitation, new_non_members)
   notify_inviter(@invitation)

   @invitation.step = 'Done'
   @invitation.draft_status = 'posted'
   @invitation.save
   flash[:notice] = "Your invitation has been successfully posted!  "
   
 
   
   flash[:fb_connect_post] = "true" if(current_member.social_network_user)

   if @invitation.invited_members.size > 0 or @invitation.invited_non_members.size > 0
    flash[:notice] <<   "Notifications have been sent to your invitees to let them know about this invite."
   end
   if(context?(:social_network))
    url = facebook_invite_friends_to_invite_url(:id => @invitation.id, :canvas => true, :only_path => false) #this has been changed on the routing level
    render :text => "<script> parent.location = '#{url}' </script> "
   elsif (mobile_request? or @viewer.member_profile.filled_in?)
    redirect_to show_invite_url(:id => @invitation.id)
   else
    redirect_to my_profile_url(:just => 'posted', :invitation_id => @invitation.id)
   end
  else
   time_date_errors.each { |attribute, error| @invitation.errors.add(attribute, error)}
   flash.now[:notice] = "Some errors prevented your invite from being posted.  Please correct the errors in each box below and hit Post Invite again."
   @address = @invitation.address
   if( context?(:social_network) )
    render_facebook_new()
   else
    render :action => 'new'
   end
  end

 end

=begin
 def save                 

  @invitation = @viewer.invitations.build
  if params[:address][:kind] == "saved"
   logger.error("trying to find address: #{params[:address][:id]}")
   @address = Address.find(params[:address][:id])
  elsif params[:address][:kind] == "yelp"
   @address = Address.new(params[:yaddress])
   # We get a country code from Google, not the country name
   @address.country = Country::COUNTRIES[params[:yaddress][:country]]
   @address.kind = "regular"
   @address.save
  else
   params[:address] = fix_address_params(params)
   @address = get_address(params[:address].dup) || Address.new(params[:address])
   @address.save
  end
  @invitation.address = @address

  (@email_addresses, @member_ids) = params["who-auto-field"].split(",").partition{ |item|  item.to_s.include?("@") }

  @member_ids = params[:member_ids].keys.collect(&:to_s).uniq unless params[:member_ids].blank?    
  @email_addresses.each{ |e| e.strip! }
  if @member_ids.blank?
   @member_ids = [] 
   @members = []
  else
   @members = Member.find(@member_ids)
  end
  @email_addresses = [] if @email_addresses.blank?
 
  # This is a hack: in order to preserve the errors on start_time/end_time, we
  # have to add them to the model after validation occurs in .save below.
  time_date_errors = { }
  @invitation.time_zone = params[:invitation][:time_zone]
  begin
   @invitation.start_time = Time.parse_with_timezone(params[:invitation][:start_time_local], params[:invitation][:time_zone])
  rescue InvalidTimeStringException => e
   logger.error "Error: #{$!} time_string was: #{params[:invitation][:start_time_local]} "
   time_date_errors[:start_time] = Invitation::EMPTY_TIME_DATE_MESSAGE
  end

  begin
   @invitation.end_time = Time.parse_with_timezone(params[:invitation][:end_time_local], params[:invitation][:time_zone])
  rescue InvalidTimeStringException => e
   time_date_errors[:end_time] = Invitation::EMPTY_TIME_DATE_MESSAGE unless time_date_errors[:start_time]
  end
  [ :start_time_local, :end_time_local].map{ |pseudo_attribute| params[:invitation].delete(pseudo_attribute)  }

  # Finally, update the invite and its address
    fix_undisclosed_address_bug() # Hack because of some weird checkbox issue during rails 2.3 upgrade.  

  @invitation.attributes = params[:invitation]
  if (params[:invitation][:purpose_id].to_i == Purpose::OTHER.id.to_i)
   @invitation.purpose = Purpose.new(:name => params[:other_purpose], :category => 'other')
  end
  
  unless (params[:address][:kind] == "saved" || params[:address][:kind] == 'yelp')
   @invitation.address.attributes = params[:address]
  end

  # Let's see if it's valid
  valid = (@invitation.save && time_date_errors.empty? && @invitation.address.save)
  if @invitation.is_private? and @member_ids.blank? and @email_addresses.blank?
   @invitation.errors.add(:invited_members, "Private invites require at least one invitee.")
   valid = false
  end
  

  if(valid)     
   update_invitees(@invitation, @member_ids, @email_addresses)    

   new_members = @invitation.invited_and_unnotified_members
   new_non_members = @invitation.invited_and_unnotified_non_members

   existing_members = (@invitation.invited_and_notified_members + @invitation.confirmed_invitees).uniq
   existing_non_members = @invitation.invited_and_notified_non_members

   invite(@invitation, new_members)
   invite_non_members(@invitation, new_non_members)
   notify_inviter(@invitation)

   @invitation.step = 'Done'
   @invitation.draft_status = 'posted'
   @invitation.save
   flash[:notice] = "Your invitation has been successfully posted!  "
   
 
   
   flash[:fb_connect_post] = "true" if(current_member.social_network_user)

   if @invitation.invited_members.size > 0 or @invitation.invited_non_members.size > 0
    flash[:notice] <<   "Notifications have been sent to your invitees to let them know about this invite."
   end
   if(context?(:social_network))
    url = facebook_invite_friends_to_invite_url(:id => @invitation.id, :canvas => true, :only_path => false) #this has been changed on the routing level
    render :text => "<script> parent.location = '#{url}' </script> "
   elsif (mobile_request? or @viewer.member_profile.filled_in?)
    redirect_to show_invite_url(:id => @invitation.id)
   else
    redirect_to my_profile_url(:just => 'posted', :invitation_id => @invitation.id)
   end
  else
   time_date_errors.each { |attribute, error| @invitation.errors.add(attribute, error)}
   flash.now[:notice] = "Some errors prevented your invite from being posted.  Please correct the errors in each box below and hit Post Invite again."
   @address = @invitation.address
   if( context?(:social_network) )
    render_facebook_new()
   else
    render :action => 'new'
   end
  end

 end
=end
  
 def quick_invite
  @invitation = Invitation.new
  render :layout => false
 end
  
 def forward_invite
  unless( @meeting = Meeting.find(params[:id], :include => :invitation, :conditions => ["events.is_public = ?", true]) rescue nil )
   redirect_to(my_invites_url()) 
   flash[:error] = "Couldn't find the invite you requested." 
   return
  end
 
  if request.post?
    if params["forward-who-auto-field"].nil? and !params["raju1#{params[:id]}"].nil?
      params["forward-who-auto-field"] = params["raju1#{params[:id]}"]
    end
   members, non_members = get_member_and_non_members(params["forward-who-auto-field"] )       
   current_member.add_contacts( (members)  | ( non_members ) )
   flash[:notice] = "You have forwarded this invite to #{( non_members.map(&:email) | members.map(&:username)).join(", ")}."
   forward_members(@meeting, members, params[:message])
   forward_non_members(@meeting, non_members, params[:message])
   redirect_to(show_invite_url(:id => @meeting.invitation, :meeting_id => @meeting))
  else
      
   @invitation = @meeting.invitation
   @inviter_name = @invitation.inviter.fullname
   @forwarder = current_member.fullname.capitalize_each_word
   @message = "I thought you might be interested ..."
   render :layout => false
  end 
 end
  
  
 def quick_post
  @invitation = Invitation.new
    
  @invitation.inviter = current_member
  if params[:private]
   @invitation.is_public = false
  else
   @invitation.is_public = true
  end
    
  # WHAT
  @invitation.name = params[:what_qi]
  @invitation.description = ''
   
  # WHERE
  name = params[:location] || params[:address]
  @address = Address.create(:name => name, 
   :address => params[:address], 
   :city => params[:city], 
   :state => params[:state], 
   :zip => params[:zip],
   :kind => 'regular')
  @invitation.address = @address
    
  # WHEN
  offset = (params[:client_tz_offset] || '-18000').to_i
  if Time.now.isdst and not ["India", "China"].include?(params[:country])
   offset -= (60*60)
  end
  tz = TimeZone.mw_us_zones.find { |z| (z.utc_offset == offset.to_i) and (z.name != 'Arizona') and (z.name != 'Indiana') } 
  tz ||= TimeZone[offset.to_i]
  @invitation.time_zone = tz.name
  @invitation.start_time = Time.parse_with_timezone(params[:quick_invite][:start_time_local], @invitation.time_zone)
  @invitation.end_time = @invitation.start_time + 1.hour
   
  # WHY
  purpose = Purpose.find_by_name(params[:why])
  if purpose
   @invitation.purpose = purpose
  else
   @invitation.purpose = Purpose.create(:name => params[:why], :category => 'other')
      
  end
    
  # Cost default to free or n/a
  @invitation.payment = Payment::FREE_OR_NA
  @invitation.activity = Activity::OTHER

  # Posted
  @invitation.draft_status = 'posted'
  @invitation.save!
    
  # WHO
  set_invitees_for_quick_invite(@invitation, params["quick-who-auto-field"])
    
  # Send the notifications.
  invite(@invitation, @invitation.invited_members)
  invite_non_members(@invitation, @invitation.invited_non_members)

  flash[:notice] = "Your QuickInvite has been successfully posted!  Notifications have been sent to your invitees to let them know about this invite."

  if(mobile_request? or (current_member.member_profile.filled_in? rescue false))
   redirect_to  show_invite_url(:id => @invitation)
  else
   redirect_to my_profile_url(:just => 'posted')
  end
	
 end

 def get_started
  @invitation = Invitation.new(:recurrence_frequency => 'weekdays')
  render :layout => false unless mobile_request? # If we add any layout stuff here then facebook needs to be updated
 end

 def get_started_post
  @invitation = Invitation.new
  @invitation.inviter = current_member
  @invitation.is_public = true
    
  # WHAT
  @invitation.name = params[:what]
  @invitation.description = params[:why] 
   
  # WHERE
  name = params[:location] || params[:address]
  @address = Address.create(:name => name, 
   :address => params[:address], 
   :city => params[:city], 
   :state => params[:state], 
   :country => params[:country], 
   :zip => params[:zip],
   :kind => 'regular')
  @invitation.address = @address
    
  # WHEN
  offset = (params[:client_tz_offset] || '-18000').to_i
  if Time.now.isdst and not ["India", "China"].include?(params[:country])
   offset -= (60*60)
  end
  tz = TimeZone.mw_us_zones.find { |z| (z.utc_offset == offset.to_i) and (z.name != 'Arizona') and (z.name != 'Indiana') } 
  tz ||= TimeZone[offset.to_i]
  @invitation.time_zone = tz.name

  @invitation.recurrence_frequency = params[:invitation][:recurrence_frequency]

  if(mobile_request?)
   mm = params[:date][0..1]
   dd = params[:date][2..3]
   yy = params[:date][4..5]
   date_str = "#{mm}/#{dd}/#{yy}"
   start_time_string = "#{date_str} #{params[:start_time][:hrs]}:#{params[:start_time][:min]} #{params[:start_time][:meridiem]}"
   end_time_string   = "#{date_str} #{params[:end_time][:hrs]}:#{params[:end_time][:min]} #{params[:end_time][:meridiem]}"
  else
   date_str = params[:date]
   # start_time[hour] will be in the form "3 AM"
   start_hour, meridiem = params[:start_time][:hour].split(' ')
   start_time_string = "#{date_str} #{start_hour}:#{params[:start_time][:minute]} #{meridiem}"
   # end_time[hour] will be in the form "3 AM"
   end_hour, meridiem = params[:end_time][:hour].split(' ')
   end_time_string = "#{date_str} #{end_hour}:#{params[:end_time][:minute]} #{meridiem}"
  end
  logger.error("START STRING: #{start_time_string}")
  logger.error("END STRING: #{end_time_string}")

  begin
   @invitation.start_time = Time.parse_with_timezone(start_time_string, @invitation.time_zone)
  rescue InvalidTimeStringException => e
   @invitation.start_time = nil
  end

  begin
   @invitation.end_time = Time.parse_with_timezone(end_time_string, @invitation.time_zone)
  rescue InvalidTimeStringException => e
   @invitation.end_time = nil
  end

  # Normally, we would ask them to fix this in validation code, but we're trying
  # to keep validation errors limited to client-side in this first cut.
  if @invitation.end_time < @invitation.start_time
   @invitation.end_time = @invitation.start_time + 1.hour
  end
   
  # WHY
  if params[:romance]
   @invitation.purpose = Purpose::ROMANCE
  else
   purpose = Purpose.find_by_name(params[:why])
   if purpose
    @invitation.purpose = purpose
   else
    @invitation.purpose = Purpose::OTHER 
   end
  end
    
  # Cost default to free or n/a
  @invitation.payment = Payment::FREE_OR_NA
  @invitation.activity = Activity::OTHER

  # Posted
  @invitation.draft_status = 'posted'
  if @invitation.save
   flash[:notice] = "Your Invite has been successfully posted!"
   flash[:fb_connect_post] = "true" if(current_member.social_network_user)

   if(mobile_request? or (current_member.member_profile.filled_in? rescue false) )
    redirect_to  show_invite_url(:id => @invitation)
   else
    redirect_to my_profile_url(:just => 'posted')
   end
  else
   render :action => 'get_started'
  end
  # #@invitation.save!
 end
  
 protected
  
 # Takes a list of emails and member names: "johnboyd, john@meetingwave.com,
 # digido" and finds the Members and NonMembers (or creates them).  The Members
 # and NonMembers are then associated with the invite.
 def set_invitees_for_quick_invite(inv, who_params)     
  
  members, non_members = get_member_and_non_members(who_params )

  members.each do |m| 
   unless(inv.invited_members.include?(m) || inv.inviter == m)
    inv.invited_members << m 
   end
  end

  unless non_members.blank?
   non_members.each do |nm| 
    nm.save_with_validation false
    inv.invited_non_members << nm 
   end  
  end
    
 end  
  
 def get_member_and_non_members(who_params)
  invitees = who_params.split(/,|;/).collect(&:strip)
  email_addresses, member_ids = invitees.partition { |invitee| invitee.match(/.*@.*/) }
      
  members  = Member.find_all_by_email(email_addresses)
  members |= Member.find(member_ids) unless member_ids.blank?
  # Any remaining emails that are not already members will be represented as
  # NonMembers.
  non_member_emails = (email_addresses - members.collect(&:email)) unless email_addresses.blank?
  unless non_member_emails.blank?
   non_members = non_member_emails.collect do |e| 
    NonMember.find_or_create_by_email(e)
   end 
  end
  members ||= []
  non_members ||= []
    
  return members, non_members
 end
  
  

 def render_facebook_new
  render :action => 'new_fbml', :layout => 'editor_fbml'
 end
  
end    



