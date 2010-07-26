module InvitationsHelper

   def none_given(msg)
      content_tag('span', msg, :class => 'hint')
   end

   def name(inv)
      if inv.name.blank?
         return none_given("No name given")
      else
         return inv.name
      end
    end
    
    

   #~ def home_page_link(invite)
     #~ location = invite.address.zip_code.zip rescue invite.address.city.capitalize
     #~ arrows = '<span style="font-family: Helvetica; font-size:17px;">&raquo;</span>'
     #~ if(location.size <= 6)
      #~ name = truncate(invite.name, 20)
     #~ else
       #~ name = truncate(invite.name, 16)
     #~ end
     #~ desc = invite.description.split('.')
     #~ link_to("#{name} - #{truncate(location, 10)} #{arrows}", show_invite_url(:id => invite.id), :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>")}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()")  
   #~ end
   
    def home_page_link(invite)
     if !invite.address.nil?

     location = invite.address.zip_code.zip rescue invite.address.city.capitalize
     arrows = '<span style="font-family: Helvetica; font-size:17px;">&raquo;</span>'
     if(location.size <= 6)
      name = truncate(invite.name, 20)
     else
       name = truncate(invite.name, 16)
     end
     desc = invite.description.split('.')
     des = desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>") if !desc[0].nil?
     des = name if desc[0].nil?
     link_to("#{name} - #{truncate(location, 10)} #{arrows}", show_invite_url(:id => invite.id), :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()") #if !desc[0].nil? 
     #~ link_to("#{name} - #{truncate(location, 10)} #{arrows}", show_invite_url(:id => invite.id), :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{desc[0]}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()") if desc[0].nil? 
   
   else
     desc = invite.description.split('.')
     des = name if desc[0].nil?
     des = desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>") if !desc[0].nil?
     link_to("#{truncate(invite.name, 20)} #{arrows}", show_invite_url(:id => invite.id), :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>")}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()")  #if !desc[0].nil?
     #~ link_to("#{name} #{arrows}", show_invite_url(:id => invite.id), :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{desc[0]}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()")  if desc[0].nil?
   end 

   end
   
    def home_page_link_private(invite,private_mw)
     if !invite.address.nil?

     location = invite.address.zip_code.zip rescue invite.address.city.capitalize
     arrows = '<span style="font-family: Helvetica; font-size:17px;">&raquo;</span>'
     if(location.size <= 6)
      name = truncate(invite.name, 20)
     else
       name = truncate(invite.name, 16)
     end
     desc = invite.description.split('.')
     des = desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>") if !desc[0].nil?
     des = name if desc[0].nil?
     link_to("#{name} - #{truncate(location, 10)} #{arrows}", signup_url, :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()")
   
   else
     desc = invite.description.split('.')
     des = name if desc[0].nil?
     des = desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>") if !desc[0].nil?
     link_to("#{truncate(invite.name, 20)} #{arrows}", signup_url, :onmouseover=>"Tip('<strong>Meeting Name</strong>:\ <br/> <p style=\"padding-left:5px;\">#{invite.name}</p> <strong>Description</strong>:\ <br/> <p style=\"padding-left:5px;\">#{desc[0].gsub(/[-\+\*\?\(\)\[\]\\\|\$\^\!\:\<\>\'\"\r]+/,"").gsub(/[\n]+/,"<br/>")}</p>', BALLOON, true, ABOVE, true, OFFSETX, -17)",:onmouseout=>"UnTip()")
   end 

   end
   
   

   
   def similar_invites(invite,invid)
     arrows = '<span style="font-family: Helvetica; font-size:17px;">&raquo;</span>'
     name = truncate(invite, 35)
     link_to("#{name} #{arrows}", show_invite_url(:id => invid))  
   end

   def whence(inv, opts = { :is_mobile => false })
      res = ''
	  separator = (opts[:is_mobile] ? ', ' : tag('br'))
      if inv.start_time_local.nil?
         res = none_given("No time given yet")
      else
		 date_fmt_string = (opts[:is_mobile] ? "%a, %b %d, %Y" : "%A, %B %d, %Y")
         res << content_tag('span', inv.start_time_local.utc.strftime(date_fmt_string), :id => 'whence_date')
         res << separator
         res << inv.start_time_local.utc.strftime("%I:%M %p")

         return res if inv.end_time_local.nil?

         # I'm intentionally not showing a span of days for recurring invites.  It complicates
         # the client-side code too much at this point.  Probably the best solution is to show a
         # duration (e.g. "one week") instead of two dates, but this will have to do for the first cut.
         if ((inv.start_time_local.day != inv.end_time_local.day) and not inv.recurring?)
		   if opts[:is_mobile]
				res << ' to '
			else
				res << '<br/> &nbsp; to <br/>'
			end
            res << inv.end_time_local.utc.strftime("%A, %B %d, %Y") << separator
            res << inv.end_time_local.utc.strftime("%I:%M %p")
         elsif (inv.start_time_local != inv.end_time_local)
            res <<  ' -- ' << inv.end_time_local.utc.strftime("%I:%M %p")
         end

      end

      res
    end
    
   def whence_show_invite(inv, opts = { :is_mobile => false })
      res = ''
	  separator = (opts[:is_mobile] ? ', ' : tag('br'))
      if inv.start_time_local.nil?
         res = none_given("No time given yet")
      else
		 date_fmt_string = (opts[:is_mobile] ? "%a, %b %d, %Y" : "%A, %B %d, %Y")
         res << content_tag('span', inv.start_time_local.utc.strftime(date_fmt_string), :id => 'whence_date')
         res << separator
         res << inv.start_time_local.utc.strftime("%I:%M %p")

         return res if inv.end_time_local.nil?

         # I'm intentionally not showing a span of days for recurring invites.  It complicates
         # the client-side code too much at this point.  Probably the best solution is to show a
         # duration (e.g. "one week") instead of two dates, but this will have to do for the first cut.
         if ((inv.start_time_local.day != inv.end_time_local.day) and not inv.recurring?)
		   if opts[:is_mobile]
				res << ' to '
			else
				res << '<br/> &nbsp; to <br/>'
			end
            res << inv.end_time_local.utc.strftime("%B %d, %Y") << separator
            res << inv.end_time_local.utc.strftime("%I:%M %p")
         elsif (inv.start_time_local != inv.end_time_local)
            res <<  ' -- ' << inv.end_time_local.utc.strftime("%I:%M %p")
         end

      end

      res
    end    
    
   def whence_for(inv, opts = { :is_mobile => false })
      res = ''
	  separator = (opts[:is_mobile] ? ', ' : tag('br'))
      if inv.start_time_local.nil?
         res = none_given("No time")
      else
         res << content_tag('span', inv.start_time_local.utc.strftime("%a, %b %d"), :id => 'whence_date')
         return res
      end
      res
    end  
    
   def whence_for_time(inv, opts = { :is_mobile => false })
      res = ''
	  separator = (opts[:is_mobile] ? ', ' : tag('br'))
      if inv.start_time_local.nil?
         res = none_given("No time")
      else
         res << inv.start_time_local.utc.strftime("%I:%M %p")
         return res
      end
      res
   end  
  
   def whence_for_today_check(inv, opts = { :is_mobile => false })
      #~ res = ''
	  separator = (opts[:is_mobile] ? ', ' : tag('br'))
      if inv.start_time_local.nil?
         res = 0
      else
        if inv.start_time_local.strftime("%A, %b %d") == Time.now.strftime("%A, %b %d")
          res = 1
        end 
         return res
      end
      res
    end  
  
   def recurring_whence_for(inv, meeting = nil)
     return whence_for(inv) unless inv.recurring?
     res = ''

     # First, get the correct start_time.  
     start_time = nil
     if !inv.posted?
       if inv.start_time_local.nil?
         return none_given("No time")
       else
         start_time = inv.start_time_local if !inv.start_time_local.nil?
       end
     else
       start_time = (meeting || inv.upcoming_meeting).start_time_local if (meeting || inv.upcoming_meeting)
     end

     # Format the start date.
	 if start_time
		 res << content_tag('span', start_time.strftime("%a, %b %d"), :id => 'whence_date')
	 end
     return res if inv.duration.nil?
     return res
   end  

   def recurring_whence_for_today_check(inv, meeting = nil)
     return whence_for_today_check(inv) unless inv.recurring?
     #~ res = ''

     # First, get the correct start_time.  
     start_time = nil
     if !inv.posted?
       if inv.start_time_local.nil?
         return none_given("No time")
       else
         start_time = inv.start_time_local if !inv.start_time_local.nil?
       end
     else
       start_time = (meeting || inv.upcoming_meeting).start_time_local if (meeting || inv.upcoming_meeting)
     end

     # Format the start date.
	 if start_time
     if start_time.strftime("%A, %b %d") == Time.now.strftime("%A, %b %d")
      res = 1
     end
	 end
     return res if inv.duration.nil?
     return res
   end  


 def recurring_whence_for_time(inv, meeting = nil)
     return whence_for_time(inv) unless inv.recurring?
     res = ''

     # First, get the correct start_time.  
     start_time = nil
     if !inv.posted?
       if inv.start_time_local.nil?
         return none_given("No time")
       else
         start_time = inv.start_time_local if !inv.start_time_local.nil?
       end
     else
       start_time = (meeting || inv.upcoming_meeting).start_time_local if (meeting || inv.upcoming_meeting)
     end

     # Format the start date.
	 if start_time
		 res << start_time.strftime("%I:%M %p")
	 end
     return res if inv.duration.nil?
     return res
   end     
   
   def simple_when(inv)
     return none_given("No time given yet") if inv.start_time_local.nil?
     res = content_tag('span', inv.start_time_local.utc.strftime("%m/%d/%Y"), :id => 'whence_date')
     res << tag('br')
     res << inv.start_time_local.utc.strftime("%I:%M %p")
     res
   end

 def recurring_whence(inv, meeting = nil)
     return whence(inv) unless inv.recurring?
     res = ''

     # First, get the correct start_time.  
     start_time = nil
     if !inv.posted?
       if inv.start_time_local.nil?
         return none_given("No time given yet")
       else
         start_time = inv.start_time_local if !inv.start_time_local.nil?
       end
     else
       start_time = (meeting || inv.upcoming_meeting).start_time_local if (meeting || inv.upcoming_meeting)
     end

     # Format the start date.
	 if start_time
		 res << content_tag('span', start_time.strftime("%A, %B %d, %Y"), :id => 'whence_date')
		 res << tag('br')
		 res << start_time.strftime("%I:%M %p")
	 end
     return res if inv.duration.nil?

     # If we have an end time, format it too.
     end_time = start_time + inv.duration if start_time
     days_later = ((end_time - start_time)/1.day).to_i if start_time

     if !days_later.nil? && days_later.zero?
       days_later = ""
     elsif days_later == 1
       days_later = ", the following day"
     else
       days_later = ", #{days_later} days later"
     end
     res << ' -- ' << end_time.strftime("%I:%M %p") << days_later if start_time

     return res
   end
   
 def recurring_whence_show_invite(inv, meeting = nil)
     return whence(inv) unless inv.recurring?
     res = ''

     # First, get the correct start_time.  
     start_time = nil
     if !inv.posted?
       if inv.start_time_local.nil?
         return none_given("No time given yet")
       else
         start_time = inv.start_time_local if !inv.start_time_local.nil?
       end
     else
       start_time = (meeting || inv.upcoming_meeting).start_time_local if (meeting || inv.upcoming_meeting)
     end

     # Format the start date.
	 if start_time
		 res << content_tag('span', start_time.strftime("%B %d, %Y"), :id => 'whence_date')
		 res << tag('br')
		 res << start_time.strftime("%I:%M %p")
	 end
     return res if inv.duration.nil?

     # If we have an end time, format it too.
     end_time = start_time + inv.duration if start_time
     days_later = ((end_time - start_time)/1.day).to_i if start_time

     if !days_later.nil? && days_later.zero?
       days_later = ""
     elsif days_later == 1
       days_later = ", the following day"
     else
       days_later = ", #{days_later} days later"
     end
     res << ' -- ' << end_time.strftime("%I:%M %p") << days_later if start_time

     return res
   end   

   def why(inv)
      if inv.purpose.nil?
         return none_given("No purpose specified")
      else
         return inv.purpose.name
      end
   end

   def activity(inv)
      if inv.activity.nil?
         return none_given("No activity specified")
      else
         return inv.activity.name
      end
   end

   def where(inv, opts = { :is_mobile =>  false} )
	 
      return none_given("No address specified") if inv.address.nil?
      result = ''
	  separator = (opts[:is_mobile] ? ', ' : tag('br'))
      addr = (inv.address.airport || inv.address)

      ## Good place to case on undisclosed.
      if(can_see_address_details(inv))
         result << inv.address.display_name if inv.address.display_name == "Open"
         result << link_to(inv.address.display_name, inv.address.link,:class => 'howitworksnew', :target => 'ttbmap') if inv.address.display_name != "Open"
         result << " "  + undisclosed_address_image_tag("invite") if( inv.undisclosed_address?  )
		 result << separator 

         case inv.address.kind   ## Possibly make undisclosed a special kind
         when "regular","conference"
            result << inv.address.address << separator if !inv.address.address.nil?
			result << inv.address.address2 << separator unless inv.address.address2.blank?
         when "airport"
            result << "Terminal/Gate: #{inv.address.terminal_gate}" << separator
         end
         result << city_state_country(inv.address)
      else
         result << undisclosed_location_detail(inv.address, "invite")

         result << content_tag(:span, l(:undisclosed_address), :style => "font-style:italic;")
      end
      if result.blank?
         result = none_given("No address specified")
      end
      result
   end     

   def where_forward(inv, opts = { :is_mobile =>  false} )
	 
      return none_given("No address specified") if inv.address.nil?
      result = ''
	  separator = ','#(opts[:is_mobile] ? ', ':)
      addr = (inv.address.airport || inv.address)

      ## Good place to case on undisclosed.
      if(can_see_address_details(inv))
         result << inv.address.display_name if inv.address.display_name == "Open"
         result << link_to(inv.address.display_name, inv.address.link, :target => 'ttbmap') if inv.address.display_name != "Open"
         result << " "  + undisclosed_address_image_tag("invite") if( inv.undisclosed_address?  )
		 result << separator 

         case inv.address.kind   ## Possibly make undisclosed a special kind
         when "regular","conference"
            result << inv.address.address << separator if !inv.address.address.nil?
			result << inv.address.address2 << separator unless inv.address.address2.blank?
         when "airport"
            result << "Terminal/Gate: #{inv.address.terminal_gate}" << separator
         end
         result << city_state_country(inv.address)
      else
         result << undisclosed_location_detail(inv.address, "invite")

         result << content_tag(:span, l(:undisclosed_address), :style => "font-style:italic;")
      end
      if result.blank?
         result = none_given("No address specified")
      end
      result
   end     


   alias :address_format :where

   def reminder_button(inv, viewer)
      r = Reminder.find_by_invitation_id_and_member_id(inv.id, viewer.id)
      check_box_tag('notify', "1", (!r.nil?), :id => "cb_#{inv.id}", :onclick => "Reminders.toggle(this, #{inv.id}, #{viewer.id});")
   end


   def reminder_button_detail(inv, viewer)
      r = Reminder.find_by_invitation_id_and_member_id(inv.id, viewer.id)
      check_box_tag('notify', "1", (!r.nil?), :id => "cb_#{inv.id}", :class => 'reminder_cb', :onclick => "Reminders.toggleWithDetails(this, #{inv.id}, #{viewer.id});")
   end

   def reminder_select_advance(reminder, inv, member)
      selected = (reminder.advance rescue member.default_reminder_advance)
      onselect = "Reminders.updateAdvance(this, $('cb_#{inv.id}'), #{inv.id}, #{member.id});"
      return select('reminder', 'advance', Reminder::ADVANCE_OPTS, {:selected => selected}, {:onchange => onselect})
   end


   def description(inv)
      if inv.description.blank?
         result = none_given("None given")
      else
         result =  inv.description
      end
      result
   end
   # Google map is using this an other helpers now.
   def host(inv, options = {})      
      link_to(inv.inviter.user_name, member_profile_url(:id => inv.inviter.user_name), :target => options[:target]) if inv.inviter
   end
    
   def host_new(inv, options = {})  

     if inv.inviter 
       if !current_member 
         if !inv.hidden_user_name.nil? 
          truncate(inv.hidden_user_name.private_name, 14)
         else 
          link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading',:target => options[:target]) 
         end 
       else 
         if inv.inviter.id == current_member.id 
          link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target]) 
         else 
           if current_member.was_approved(inv.upcoming_meeting) 
            link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target]) 
           else 
            if !inv.hidden_user_name.nil?
              truncate(inv.hidden_user_name.private_name, 14) 
            else
              link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target])
            end                              
           end 
         end 
       end 
     end 

      #~ if inv.inviter
        #~ if current_member && inv.inviter.id == current_member.id
          #~ link_to(truncate(inv.inviter.user_name, 10), member_profile_url(:id => inv.inviter.id), :target => options[:target])
        #~ else 
          #~ if !inv.hidden_user_name.nil?
            #~ link_to(truncate(inv.hidden_user_name.private_name, 10), member_profile_url(:id => inv.inviter.id), :target => options[:target])
          #~ else
            #~ link_to(truncate(inv.inviter.user_name, 10), member_profile_url(:id => inv.inviter.id), :target => options[:target])
          #~ end
        #~ end
      #~ end  
    end
    
    
    
    
    
    def host_new_not_truncate(inv, options = {})  

     if inv.inviter 
       if !current_member 
         if !inv.hidden_user_name.nil? 
          #truncate(inv.hidden_user_name.private_name, 14)
		  inv.hidden_user_name.private_name
		  
         else 
          # link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading',:target => options[:target])
		  
		   link_to(inv.inviter.user_name, member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading',:target => options[:target])  
         end 
       else 
         if inv.inviter.id == current_member.id 
          #link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target]) 
		  link_to(inv.inviter.user_name, member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target])
		  
         else 
           if current_member.was_approved(inv.upcoming_meeting) 
            #link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target]) 
			link_to(inv.inviter.user_name, member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target]) 
			
           else 
            if !inv.hidden_user_name.nil?
              #truncate(inv.hidden_user_name.private_name, 14) 
			   inv.hidden_user_name.private_name
            else
              #link_to(truncate(inv.inviter.user_name, 14), member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target])
			  link_to(inv.inviter.user_name, member_profile_url(:id => inv.inviter.id),:class => 'mymeetingheading', :target => options[:target])
			  
            end                              
           end 
         end 
       end 
     end 


      #~ if inv.inviter
        #~ if current_member && inv.inviter.id == current_member.id
          #~ link_to(truncate(inv.inviter.user_name, 10), member_profile_url(:id => inv.inviter.id), :target => options[:target])
        #~ else 
          #~ if !inv.hidden_user_name.nil?
            #~ link_to(truncate(inv.hidden_user_name.private_name, 10), member_profile_url(:id => inv.inviter.id), :target => options[:target])
          #~ else
            #~ link_to(truncate(inv.inviter.user_name, 10), member_profile_url(:id => inv.inviter.id), :target => options[:target])
          #~ end
        #~ end
      #~ end  
   end
    
    
    
    
    
    
    
    
    
    
    
    

   def costs(inv)
      inv.payment.name rescue none_given("None specified")
   end

   def size(inv)
      min = inv.minimum_invitees
      max = inv.maximum_invitees
      if min.blank? and max.blank?
         return
      elsif min and max
         return "#{min} - #{max} people"
      elsif min
         return "At least #{min} people"
      elsif max
         return "No more than #{max} people"
      end
      # result << "<span style='font-size: 0.9em'>MIN:</span> #{pluralize(inv.minimum_invitees, 'person')} <br/>" unless inv.minimum_invitees.blank?
      #     result << "<span style='font-size: 0.9em'>MAX:</span> #{pluralize(inv.maximum_invitees, 'person')} <br/>" unless inv.maximum_invitees.blank?

   end

   def accept_button(meeting, viewer)
      return (viewer.accepted(meeting) ? accept_off : accept_on(meeting))
   end

   def accept_off()
      img = off_button_image('accept_off', :alt => "ACCEPT", :width => "80", :height => "26")
      link_to_remote(img, {:url => '#', :submit => 'rsvp_form' }, {:id => 'accept_button'})
   end

   def accept_on(meeting = nil)
      img = button_image('accept', :alt => "ACCEPT", :width => "80", :height => "26")
      link_to_remote(img, {:url => accept_url(:id => (meeting.id rescue nil)), :submit => 'rsvp_form' }, {:id => 'accept_button'})
   end
   
   def forward_button(meeting)
      img = button_image('forward', :alt => "FORWARD", :id => "forward-button")
      content_tag(:a, img, :href => "#", :rel => "ibox&type=3&height=625&width=700&url=/forward_invite/#{meeting.id}") 
     
   end

   def decline_button(meeting, viewer)
      return (viewer.declined(meeting) ? decline_off : decline_on(meeting))
   end

   def decline_on(meeting = nil)
      img = button_image('decline',  :alt => "DECLINE", :width => "78", :height => "26")
      link_to_remote(img, {:url => decline_url(:id => (meeting.id rescue nil)), :submit => 'rsvp_form'}, {:id => 'decline_button'})
   end

   def decline_off
      img = off_button_image('decline_off',  :alt => "DECLINE", :width => "78", :height => "26")
      link_to_remote(img, {:url => '#', :submit => 'rsvp_form'}, {:id => 'decline_button'})
   end

   def edit_button(inv)
      img = button_image('edit',  :alt => "EDIT", :height => "26")
      link_to(img, edit_url(:id => inv.id), :title => 'EDIT')
   end

   def copy_button(inv)
      img = button_image('copy',  :alt => "COPY", :height => "26")
      link_to(img, copy_url(:id => inv.id), :title => 'COPY THIS INVITE')
   end

   def view_messages_button(inv)
      img = image_tag('/images/ttb/icons/email.gif',  :alt => "VIEW MESSAGES",  :height => "16")
      link_to(img, invite_messages_url(:id => inv.id))
   end

   def watch_button(meeting, viewer)
      if(viewer and viewer.is_watching(meeting))
         return watch_off
      else
         return watch_on(meeting, viewer)
      end
   end

   def watch_off
      img = off_button_image('watch_off',  :alt => "WATCH",  :height => "26")
      link_to_remote(img, {:url => '#', :submit => 'rsvp_form'}, {:id => 'watch_button'})
   end

   def watch_on(meeting = nil, viewer = nil)
      img = button_image('watch',  :alt => "WATCH",  :height => "26")
      link = watch_url(:id => (meeting.id rescue nil))
      if viewer
         spinner_id = "watch_spinner_#{Time.now.to_i}"
         the_button = link_to_remote(img, {:url => link, 
                                            :submit => 'rsvp_form',
                                            :before => "Element.hide('watch_button');Element.show('#{spinner_id}')",
                                            :complete => "Element.hide('#{spinner_id}')"}, {:id => 'watch_button'})
               the_button  += image_tag('/images/ttb/spinner.guest_response.gif', :style => 'display:none;', :id => spinner_id)

      else
         return link_to(img, link)
      end
   end

   def delete_button(inv)
      return '' if inv.expired?
      img = button_image('delete',  :alt => "DELETE",  :height => "26")
      link_to(img, confirm_delete_url(:id => inv.id))
   end

   def confirm_delete_button(inv)
      return '' if inv.expired?
      img = button_image('delete',  :alt => "DELETE",  :height => "26")
      link_to(img, confirm_delete_url(:id => inv.id))
   end

   def attend_button(meeting, viewer)
      return attend_logged_off(meeting.invitation) if viewer.nil?
      return ((viewer.requested_invitation(meeting) || viewer.was_rejected(meeting) || viewer.attending(meeting)) ? attend_off : attend_on(meeting))
   end

   def attend_logged_off(inv)
      img = button_image('attend',  :alt => "REQUEST_INVITATION",  :height => "26")
      return link_to(img, login_and_respond_to_url(:id => inv.id))
   end

   def attend_on(meeting = nil)
      img = button_image('attend',  :alt => "REQUEST_INVITATION",  :height => "26", :id => "attend-on-button")
      return link_to_function(img, 'attend();', :id => 'attend_button')
   end

   def attend_off
      img = off_button_image('attend_off',  :alt => "REQUEST_INVITATION",  :height => "26", :id => "attend-off-button")
      return link_to_remote(img, {:url => '#', :submit => 'rsvp_form'}, {:id => 'attend_button'})
   end

   def pre_verified_signup_button(acc_or_dec, non_member)
      img = button_image(acc_or_dec.to_s,
      :alt => "ACCEPT", :width => "80", :height => "26")
      link = pre_verified_signup_url(:response => acc_or_dec,
      :security_token => non_member.security_token)
      link_to(img, link)
   end
   
   def guest_response_sidebar_row(meeting, invitee, klass)
	 res = ''
	 if invitee.is_a?(Member)
	   res << content_tag('td', link_to(invitee.user_name, member_profile_url(:id => invitee.user_name), :title => invitee.user_name, :alt => invitee.user_name))
	   conf = meeting.confirmations.find_by_member_id(invitee.id) 
	   if (conf.nil? or (conf.status == Status['new']))
		 status = 'Invited'
	   elsif conf.status.simple_name == 'Attending' && meeting.expired?
		 status = 'Attended'
	   else
		 status = conf.status.simple_name
	   end
	   res << content_tag('td', status)
	 else
	   res << content_tag('td', invitee["name"] || invitee.email)
	   res << content_tag('td', 'Invited')
	 end
	 content_tag('tr', res, :class => klass)
   end

   def outstanding_rsvp_sidebar_row(meeting, invitee, klass)
	 res = ''
	 row_id = "outstanding_#{invitee.id}"
	 spinner_id = "spinner_#{row_id}"
	 if invitee.is_a?(Member)
	   res << content_tag('td', link_to(truncate(invitee.user_name, 6), member_profile_url(:id => invitee.user_name), :title => invitee.user_name, :alt => invitee.user_name))
	   select = select_tag('new_status', options_for_select(['Approve', 'Declined']), :id => "new_status_for_#{invitee.id}", :class => 'new_status',:style => "width:75px;") 
	   res << content_tag('td', select , :class => "new_status_container")
	   url = quick_approve_reject_url(:meeting_id => meeting.id, :invitee_id => invitee.id)
       link = link_to_remote(button_image('ok_small',:border => "0",:align => "absmiddle"), { :url => url, 
																		     :submit => row_id, 
																			 :loading => "Element.hide('button_#{invitee.id}'); Element.show('#{spinner_id}');"}, 
																		   { :id => "button_#{invitee.id}"})
	   link << image_tag("/images/ttb/spinner.guest_list.#{klass}.gif", :style => "display: none;", :id => spinner_id, :class => "gl_spin")
	   res << content_tag('td', link, :class => 'new_status_button_container' )
	 end
	 content_tag('tr', res, :class => klass, :id => row_id )
   end

   # This method reflects the difference in approach between mobile and non-mobile 
   # clients for this fucntionality.  The BlackBerry does not hide the spinners, 
   # nor does it seem to allow the same AJAX submission (link_to_remote) that we're 
   # using for regular browsers.
   def mobile_outstanding_rsvp_sidebar_row(meeting, invitee, klass)
	 res = ''
	 row_id = "outstanding_#{invitee.id}"
	 if invitee.is_a?(Member)
	   res << content_tag('td', link_to(truncate(invitee.user_name, 18), member_profile_url(:id => invitee.user_name), :title => invitee.user_name, :alt => invitee.user_name))
	   select = select_tag("status_for_#{invitee.id}", options_for_select(['Approve', 'Decline'])) 
	   res << content_tag('td', select, :class => 'approve_decline')
	 end
	 content_tag('tr', res, :class => klass, :id => row_id )
   end

   


   def options_for_location
      if @address.id
         return {}
      else
         return { 'value' => '(e.g., restaurant name)', 'onClick' => %q{document.getElementById('address_name').value='';}}
      end
   end

   def accept_or_decline_url(resp, confirmation)
      self.send("#{resp}_url", {:id => confirmation.meeting.id})
   end

   VERIFIED_HELP = 'This email has already been verified!  You can complete this form and login immediately.  If you want to change this email address, you will have to verify your new address before logging in.'
   UNVERIFIED_HELP = 'This email is different than the one this invitation was originally addressed to.  You can use this different email address, but you will need to verify it by clicking a link that will be emailed to you when you click the "Signup" button.'
   def pre_verified_email_tool_tip(member, non_member)
      tool_tip('Email Pre-Verified', VERIFIED_HELP,
      :image => indicator_path('greencheck_white'),
      :image_class =>  (member.email == non_member.email ? '' : 'hidden'), :id => 'verified_tt')
   end
   def not_verified_email_tool_tip(member, non_member)
      style = "display: none;" unless member.email != non_member.email
      tool_tip('Email Not Verified', UNVERIFIED_HELP,
      :image => indicator_path('greenexclamation_white'), 
      :style => style, :id => 'not_verified_tt')
   end

   def display_recurring_confirmations(inv, mem)   
      return (inv.recurring? and mem)
   end

   def guest_response_header(meeting, viewer)
     invitation = meeting.invitation
         date_str = content_tag('span', sh_date_yr(meeting.start_time_local).upcase, :class => 'gr_meeting')
         # res = "GUEST RESPONSE FOR #{date_str}"
         res = "GUEST RESPONSE"
         
         if (viewer == invitation.inviter)
            res = link_to(res, guest_response_url(:id => meeting.id))
         end
         return content_tag('h3', res, :class => 'guest_response')
   end

   def messages_header(meeting)
        date_str = content_tag('span', sh_date_yr(meeting.start_time_local).upcase, :class => 'gr_meeting')
         # res = "MESSAGES FOR #{date_str}"
         res = "MESSAGES"
         
         return content_tag('h3', res)
   end

   def js_conf_id(conf)
      # JS uses zero-based months
      d = conf.meeting.start_time_local
      y, m, day = d.year, (d.month - 1), d.day
      "conf_#{y}#{m}#{day}#{conf.id}"
   end

   def guest_responses_awaiting_approval(meeting)
    	link = guest_response_url(:id => meeting.id)
		  image_link = link_to(image_tag('/images/ttb/alert_guy.gif', :id => 'guest_response_alert_icon'), link)
			text_link = link_to("You have #{pluralize(meeting.invitation.confs_accepted.size, 'acceptance')} awaiting your approval.", link)
			text_link = content_tag('div', text_link, :id => 'guest_response_alert_text')
      content_tag('div', image_link + text_link)
   end
   
   def invite_name_field(invitation, klass)
       (invitation.confs_accepted.size > 0) ? "confs_accepted_#{klass}" : "no_confs_accepted" 
   end
   
   def tooltip_recurring(title=true)
     str = 'This is a recurring invite. Click on the invite name for more information.'
     return title ? "title=\"#{str}\"" : str 
   end

   def tooltip_acceptances(invitation)
     str = ''
     if invitation.current_confs_accepted.size > 0
       str = 'title="This invite has acceptances awaiting your approval. Click on the invite name for more information."'
     end
     return str
   end

   def acceptances_notice(invitation)
     all_acceptances_notice = full_list_of_acceptances_awaiting_response(invitation)
     if all_acceptances_notice.blank?
       return ''
     else
       return content_tag('div', all_acceptances_notice, :id => 'all_acceptances_notice', :class=> 'sidebar-box')
     end
   end
   
  
 
       def private_indicator(inv)
         
          if inv.is_private?
            msg = 'This is a private invite.'
            return image_tag('/images/ttb/lock.invite.gif', :alt => msg, :title => msg)
          end
       end
      
       def private_indicator_dashboard(inv, klass)
         if inv.is_private?
           msg = 'This is a private invite.'
           return '&nbsp;' + image_tag("/images/ttb/lock.#{klass}.small.gif", :alt => msg, :title => msg)
         end
       end


	   def mobile_buttons(meeting, viewer)
		 invitation = meeting.invitation
		 buttons = [ ]
		 result = ''
		 if meeting.expired? 
		   result << content_tag('h3', 'EXPIRED', :class => 'expired') 
		   if(viewer and viewer.owner(invitation)) 
			 buttons <<  confirm_delete_button(invitation) 
		   end
		 elsif viewer.nil? 
		   buttons << attend_button(meeting, viewer) 
		   buttons << watch_button(meeting, viewer) 
		 elsif viewer.owner(invitation) 
		   buttons << edit_button(invitation)  
		   buttons << confirm_delete_button(invitation)
		 elsif viewer.invited_to(invitation) or viewer.was_approved(meeting) 
		   # ACCEPT BUTTON
		   if viewer.accepted(meeting)
			 # Greyed-out image 
			 buttons << off_button_image('accept', :alt => "ACCEPT", :width => "80", :height => "26")
		   else
			 # Active accept link
			 buttons << link_to(button_image('accept', :alt => "ACCEPT", :width => "80", :height => "26"), accept_url(:id => (meeting.id rescue nil)))
		   end
		   # DECLINE BUTTON
		   if viewer.declined(meeting) 
			 # Greyed-out image 
			 buttons << off_button_image('decline',  :alt => "DECLINE", :width => "78", :height => "26")
		   else 
			 # Active decline link
			 buttons << link_to(button_image('decline', :alt => "DECLINE", :width => "78", :height => "26"),  decline_url(:id => (meeting.id rescue nil)))
		   end
		 else 
		   # ATTEND BUTTON
		   if(viewer.nil?)
			 buttons << attend_logged_off(meeting.invitation)
		   elsif(viewer.requested_invitation(meeting) || viewer.was_rejected(meeting) || viewer.attending(meeting))
			 buttons << off_button_image('attend',  :alt => "REQUEST_INVITATION",  :height => "26")
		   else
			 img = button_image('attend',  :alt => "REQUEST_INVITATION",  :height => "26")
			 buttons <<  link_to(img, attend_url(:id => (meeting.id rescue nil)))
		   end

		   # WATCH BUTTON
		   if(viewer and viewer.is_watching(meeting))
			 buttons << off_button_image('watch',  :alt => "WATCH",  :height => "26")
		   else
			 img = button_image('watch',  :alt => "WATCH",  :height => "26")
			 buttons << link_to(img, watch_url(:id => (meeting.id rescue nil)))
		   end
		   
		 end 
		 
		 result << make_buttons_table(buttons) unless buttons.blank?
		 
		 
		 #result << form_tag() 
		 #result << content_tag('h5', 'Include a Message for the Inviter:') 
		 #result << text_area_tag('message[body]', nil, :size => '40x2')

		 return result 
		 
       end
	   
	   def make_buttons_table(buttons)
		 buttons_row = content_tag('tr', buttons.collect{ |b| content_tag('td', b)})
		 return content_tag('table', buttons_row, :class => 'button_box')
       end

	   ACCEPTED = "Someone has accepted this invite!"
	   def confs_accepted_note(inv)
		 image_tag("/images/ttb/large_alert_guy.gif", :alt => ACCEPTED, :title => ACCEPTED,:align =>"absmiddle") unless inv.current_confs_accepted.size.zero? 
	   end



	   def acceptances_awaiting_response_table(invitation, current_meeting = nil)
		 confs_grouped_by_meeting_id = invitation.current_confs_accepted.group_by(&:meeting_id)
		 confs_grouped_by_meeting_id.delete(current_meeting.id) unless current_meeting.nil?
		 return '' if confs_grouped_by_meeting_id.size.zero?
		 header = content_tag('h2', 'OTHER MEETINGS', :class => 'invitename') 
		 sorted_dates = confs_grouped_by_meeting_id.keys.sort
		 links = sorted_dates.collect do |meeting_id|
		   meeting = Meeting.find(meeting_id)   
		   confirmations = confs_grouped_by_meeting_id[meeting_id]
		   date_string = meeting.start_time_local.strftime("%b %d").upcase
		   link_to("#{pluralize(confirmations.size, 'person')} wants to meet <b>#{date_string}</b>", guest_response_url(:id => meeting_id)) 
		 end
		 table = '<table class="guestlist" width="100%" > '
		 links.each do |link|
		   table << content_tag('tr', content_tag('td', link), :class => cycle('even', 'odd'))
		 end
		 table << '</table>'
		 
		 return "#{header} #{table}" 
	   end  
           
#These methods are here for caching purposes.. They were moved from the controller.
    
  def setup_invites_for_upcoming
   if( @upcoming_near_me.blank? )
    @upcoming_near_me = Invitation.search "#{@current_city} #{@current_state} #{@current_country}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0}, :without => {:purpose_id => 19}, :order => :id, :sort_mode => :desc
    #~ @upcoming_near_me = LookUp::meetings_for_upcoming_on_user_home(:city => @current_city, :state => @current_state, :country => @current_country) 
    @invites_for_map  = LookUp::invites_for_map_on_user_home(@upcoming_near_me.map(&:id))
   end
  end  

  
  def setup_my_invites
    @buckets = { }
    @confirmed = @viewer.confirmed_as_guest(@univ_account) # Returns Meetings
    @confirmed.each { |c| @buckets[c] = "accepted confirmed" }

    @received  = @viewer.received_invites(@univ_account)  # Returns Invitations
    @received.each { |r| @buckets[r.upcoming_meeting] = "received" }

    @posted    = @viewer.posted_invites.collect { |i| (i.upcoming_meeting rescue nil)  }.flatten # Returns Meetings   
    @posted.each { |p| @buckets[p] = "posted" }


    @confirmed_posted = @viewer.confirmed_posted
    @confirmed_posted.each do |cp| 
      if @buckets[cp]
        @buckets[cp] << " confirmed" 
      else
        @buckets[cp] = " confirmed" 
      end
    end
    @confirmed << @confirmed_posted

    @accepted  = @viewer.future_confirmations('ACCEPTED',@univ_account).collect { |c| c.meeting}  
    @accepted.each { |a| @buckets[a] = "accepted" }

    @my_invitations = [@posted, @confirmed, @accepted, @received ].flatten.uniq
    @my_invitations.sort do |a, b| 
      a_mtg = (a.is_a?(Meeting) ? a : (a.upcoming_meeting rescue a))
      b_mtg = (b.is_a?(Meeting) ? b : (b.upcoming_meeting rescue b))
      a_mtg.start_time_local <=> b_mtg.start_time_local
    end

    # These are still used by the mobile version
    @confirmed.flatten!
    @confirmed.compact!

    @watching ||= []
    @my_invitations
  end
  
  def setup_archived_meetings
    @archived_buckets = { }
    @posted_meetings = @viewer.past_posted_invites.map(&:past_meetings).flatten.sort_by(&:start_time).reverse  
    @posted_meetings = @posted_meetings.delete_if { |pm| pm.confirmed_invitees.size.zero? }
    @posted_meetings.each { |m| @archived_buckets[m] = "archive-posted" }
    @attended_meetings = @viewer.past_attended_meetings.sort_by(&:start_time).reverse 
    @attended_meetings.each { |m| @archived_buckets[m] = "archive-attended" }
    @archived_meetings = (@posted_meetings + @attended_meetings).sort { |a, b| b.start_time <=> a.start_time }
  end
  
  def related_invites_as_list
    list_items = []
    
    LookUp.related_invites(@meeting).each{|invite|
      next unless invite.address
      
      inside_li =  short_link(invite, nil, 40)
      inside_li +=  content_tag(:span , city_state_country(invite.address, :zip => false))
      list_items << content_tag(:li, inside_li )

      }
    
    list_items.join("\n")
  end

 end
	 
