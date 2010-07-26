module InvitationNotifyHelper  
  include ApplicationHelper
  include InvitationsHelper
  
  BODY_STYLE = "font: 1.2em arial; text-align:left; color: #42412d; padding: 25px;"
  HEADLINE_STYLE = "font: 1.5em arial; text-align: left; font-weight: bold; color: #155E8D; width:100%; padding:10px 25px 5px 25px;"
  MESSAGE_INTRO_STYLE = "font-style:italic; margin-top:15px"
  MESSAGE_BODY_STYLE =  "padding-left: 30px; padding-right: 30px; margin-top: 2px; color: #42412d; font-weight: bold;"  
  MESSAGE_DETAILS_STYLE =  "padding-left: 40px; padding-right: 40px; margin-top: 2px; color: #42412d; font-weight: bold;"

  HIGHLIGHT_STYLE = "font: 1.2em arial; font-weight: bold; color: #000;"
  BROUGHT_TO_YOU_BY_STYLE = "margin-top: 10px; font-size: 0.6em;"

  def host_with_port
   case RAILS_ENV
   when 'development'
    "localhost:3000"
   when 'production'
     "www.meetingwave.com"
   else
     "#{RAILS_ENV}.meetingwave.com"
   end
  end
  
    def request_comes_from_facebook?
       false
      end
  
  def invite_report_intro   
   "Your Meeting Alert \"#{@saved_search.name}\" resulted in the following new 
    opportunities to network with people. Remember that if the time or 
    location doesn't work for you, you and the organizer can find a new 
    time or place using our double blind email communication."
  end
  
  def invite_report_appology
   "If you don't see a meeting of interest, try posting your own at 
    MeetingWave.com. Remember, you can use MeetingWave to meet new clients, 
    network with others in your industry, connect with potential investors, 
    find new opportunities, or make new business contacts or friends."
  end
  
  def invite_report_hello_user
   "Dear #{@saved_search.member.username},"
  end
  
  def invite_report_marketing_blurb
   <<EOL
  <p>
    If you don't see a meeting of interest in this Meeting Alert, try 
    #{ link_to("posting your own Invite", postinvite_url) } at MeetingWave.com. 
    Remember, you can use MeetingWave to 
    meet new clients, network with others in your industry, connect with 
    potential investors, find new opportunities, or make new business 
    contacts or friends.
  </p>
  <p>
    Please keep in mind a meeting is only confirmed after your acceptance is 
    approved by the member who posted the invite. MeetingWave will notify you 
    of the other member's decision confirming the meeting.
  </p>
  <p>
    If you have any questions, comments, or feedback, please #{link_to("let us know", contact_us_url)}. 
    To cancel this Meeting Alert, login to you account and hit delete on your 
    meeting alert. 
  </p>
  <p>
    The MeetingWave Team
  </p>
EOL
   
  end
  
  def invite_report_marketing_blurb_text
   <<EOL
   
    If you don't see a meeting of interest in this Meeting Alert, try 
    posting your own Invite : #{  postinvite_url } at MeetingWave.com. 
    Remember, you can use MeetingWave to 
    meet new clients, network with others in your industry, connect with 
    potential investors, find new opportunities, or make new business 
    contacts or friends.
  
    Please keep in mind a meeting is only confirmed after your acceptance is 
    approved by the member who posted the invite. MeetingWave will notify you
    of the other member's decision confirming the meeting.
  
    If you have any questions, comments, or feedback, please let us know. 
    #{contact_us_url}
    To cancel this Meeting Alert, login to you account and hit delete on 
    your meeting alert. 
  
  
    The MeetingWave Team
 

EOL
   
  end
  
  def recurring_note
   "Also, the following recurring meetings are still going on that meet your criteria: "
  end
  
  def default_host_options
      {:host => host_with_port}
  end
  def headline(txt)
    content_tag('tr', content_tag('td', txt, :style => HEADLINE_STYLE))
  end

  def message(person, msg)
    return if msg.nil?
    result = content_tag('p', "#{person.capitalize_each_word} says:", :style =>  MESSAGE_INTRO_STYLE)
    result << content_tag('p', @message, :style => MESSAGE_BODY_STYLE, :id => "internal_message")
  end                                                     
  
  def recipients(recipient,broadcast)
    broadcast ? 'All invitees' : recipient
  end

  def open_body
    %{<tr> <td style="#{BODY_STYLE}">}
  end

  def close_body
    '</td></tr>'
  end

  def open_highlight
    %{<span style="#{HIGHLIGHT_STYLE}"> }
  end  

  def highlight
	  result = open_highlight
	  result <<  yield
	  result << close_highlight
	end

  def close_highlight
    '</span>'
  end

  def invited_as(conf)
      "(#{conf.invited_as})" unless(conf.nil? or conf.invited_as.blank?) 
  end

  def rsvp_button(url)
    %{<tr>
      <td style="padding-bottom: 20px;"> 
        <center>
          <a href="#{url}" style="border: 0;"><img src="http://#{host_with_port}/#{button_path('rsvp')}" border="0" /></a>
        </center>
      </td> 
    </tr> 
    #{in_case_of_link_stripping(url, 2)}
    }
  end

  def invitation_button(url)
    %{<tr>
      <td style="padding-bottom: 20px;"> 
        <center>
          <a href="#{url}" style="border: 0;"><img src="http://#{host_with_port}/#{button_path('view_invite')}" border="0" /></a>
        </center>
      </td> 
    </tr>
    #{in_case_of_link_stripping(url)}
     }
  end
  def in_case_of_link_stripping(url, top_padding = 25)
    %{ <tr>
         <td style="font: 11px arial; color: #42412d; padding: #{top_padding}px 25px 5px 25px;" align="center">
           If the above button does not work, please copy and paste this URL into your web browser:<br/>  
         </td>
       </tr>
       <tr>
         <td  style="font: 11px arial; color: #42412d; padding: 0px; font-weight: bold;" align="center">
           #{url}
         </td>
       </tr>    
     }
  end

  def brought_to_you_by 
      %{<tr>
        <td style="font: 1.0em arial; color: #42412d; padding: 25px;">
          <p style="#{BROUGHT_TO_YOU_BY_STYLE}">This message was brought to you by <a href="http://www.meetingwave.com" style="color: #155E8D;">MeetingWave.com</a>, a business/social networking tool that helps you connect offline with people you would like to meet in the places you will be - anytime, anyplace. You're receiving this email because you or a friend are members of <a href="http://www.meetingwave.com" style="color: #155E8D;">MeetingWave.com</a>. 
          </p>
        </td>
      </tr> }
  end  
    
#Copied and modified from invitations helper. What should we do .  -- Tdave
def where(inv)
   return none_given("No address specified") if inv.address.nil?
   result = []
   addr = (inv.address.airport || inv.address)

   result << link_to(inv.address.display_name, inv.address.link, :target => 'ttbmap')
   result << "<br/>"

   case inv.address.kind   ## Possibly make undisclosed a special kind
   when "regular","conference"
      result << inv.address.address << "<br/>" 
      result << inv.address.address2 << "<br/>"  unless inv.address.address2.blank?
   when "airport"
      result << "Terminal/Gate: #{inv.address.terminal_gate}" << "<br/>" 
   end
   ci_st_co = [addr.city, addr.state, addr.country].delete_if{ |a| a.blank? }
   result << ci_st_co.join(', ').sub(/, United States$/, '')

   if result.blank?
      result = none_given("No address specified")
   end      

   result 
end   
       
 def where_text(inv) 
	  # Clean them html tags and space it out correctly.
	  where(inv).map{|string|  string.gsub(/<.*?>/,"") if !string.nil?  }.reject(&:blank?).join( "\n" + (" " * 8))
 end 

 def why(inv)
    if inv.purpose.nil?
       return none_given("No purpose specified")
    else
       return inv.purpose.name
    end
 end


  def message_txt(person, msg)
    return if msg.nil?
    result =  "#{person.capitalize_each_word} says:\n"
    result << word_wrap(msg) 
    result
  end

  def brought_to_you_by_txt
      word_wrap(%{This message was brought to you by MeetingWave.com (http://www.meetingwave.com), a business/social networking tool that helps you connect offline with people you would like to meet in the places you will be - anytime, anyplace.  You're receiving this email because you or a friend are members of MeetingWave.com.  Please add noreply@meetingwave.com to your contacts list to avoid having these emails automatically blocked from your inbox.})
  end

 def changed_attr_format(val, old_or_new)

   txt = ''
   if val[old_or_new].blank?
     txt = (old_or_new == 'old' ? '[ None given. ]' : '[ Deleted. ]')
     txt = content_tag('span', txt, :style => "font-style: italic; padding-top: 3px;")
   elsif val[old_or_new].is_a?(Time)
     txt = val[old_or_new].utc.strftime("%a, %b %d, %Y") 
     txt << tag('br')
     txt << val[old_or_new].utc.strftime("%I:%M %p")
   else
     txt = val[old_or_new]
   end
   return txt
 end

 def changed_attr_format_txt(val, old_or_new)
   txt = ''
   if val[old_or_new].blank?
     txt = (old_or_new == 'old' ? '[ None given. ]' : '[ Deleted. ]')
   elsif val[old_or_new].is_a?(Time)
     txt = val[old_or_new].utc.strftime("%a, %b %d, %Y") 
     txt << ' -- '
     txt << val[old_or_new].utc.strftime("%I:%M %p")
   else
     txt = strip_tags(val[old_or_new].gsub(/\s*<br\/>/i, ', '))
   end
   return txt
 end

 def changed_attr_name(key)
    key = key.chomp("_local") if (key == "start_time_local" or key == "end_time_local")
    key.humanize
 end
 
 def start_time(inv)
  if inv.no_pref != 1
	  inv.start_time_local.strftime("%A, %B %d, %Y at %I:%M %p") rescue ''
  else
  	  "No Preference"
  end
 end
 
 def member_thumb_or_default(member, options = {})
  if(member.member_profile.picture rescue false)
           image_tag(thumb_url(:id => member.member_profile.picture.id, :host => host_with_port), {:format => "jpg", :alt => ''}.merge(options) ) 
  else
               image_tag("http://#{host_with_port}/images/ttb/default_pic.jpg", {:format => "jpg", :alt => ''}.merge(options) ) 

  end
 end

 def all_changed_attrs_txt(changed_attributes )
   res = ''
   Invitation::SORTED_ATTRS_FOR_CHANGE_NOTE.each do |key| 
     unless changed_attributes[key].blank? 
       res << "  Item:       #{changed_attr_name(key)}\r\n"
       res << "    From:       #{changed_attr_format_txt(changed_attributes[key], 'old')}\r\n"
       res << "    To:         #{changed_attr_format_txt(changed_attributes[key], 'new')}\r\n"
       changed_attributes.delete(key) 
     end
   end
   changed_attributes.each_key do | key | 
     begin
       res << "  Item:       #{changed_attr_name(key)}\r\n"
       res << "     From:       #{changed_attr_format_txt(changed_attributes[key], 'old')}\r\n"
       res << "     To:         #{changed_attr_format_txt(changed_attributes[key], 'new')}\r\n"
     rescue => e
       logger.error("Error: Some changed attributes were not recorded: #{$!}.")
     end
   end
   res
 end 

 def all_changed_attrs_fbml(changed_attributes )
   res = []
   Invitation::SORTED_ATTRS_FOR_CHANGE_NOTE.each do |key| 
     unless changed_attributes[key].blank? 
       res << "  Item:       #{changed_attr_name(key)}\r\n"
       res << "    From:       #{changed_attr_format_txt(changed_attributes[key], 'old')}\r\n"
       res << "    To:         #{changed_attr_format_txt(changed_attributes[key], 'new')}\r\n"
       changed_attributes.delete(key) 
     end
   end
   changed_attributes.each_key do | key | 
     begin
       res << "  Item:       #{changed_attr_name(key)}\r\n"
       res << "     From:       #{changed_attr_format_txt(changed_attributes[key], 'old')}\r\n"
       res << "     To:         #{changed_attr_format_txt(changed_attributes[key], 'new')}\r\n"
     rescue => e
       logger.error("Error: Some changed attributes were not recorded: #{$!}.")
     end
   end
   content_tag(:p, res.join("</p><p>"))
 end

 def all_changed_attrs(changed_attributes )
   res = ''
   Invitation::SORTED_ATTRS_FOR_CHANGE_NOTE.each do |key| 
     next if changed_attributes[key].blank? 
     res << '<tr style="vertical-align: top;" valign="top" ><td style="color: #000; font-size: 14px; font-weight:bold;">' 
     res << changed_attr_name(key) 
     res <<'</td><td style="padding-left: 15px; ">'
     res << changed_attr_format(changed_attributes[key], 'old') 
     res << '</td><td style="padding-left: 20px; ">'
     res <<  changed_attr_format(changed_attributes[key], 'new') 
     res <<  '</td></tr>'
     changed_attributes.delete(key)  
   end 

   changed_attributes.each_key do | key | 
     begin
     res << '<tr style="vertical-align: top;" valign="top" ><td style="color: #000; font-size: 14px; font-weight:bold;">' 
     res << changed_attr_name(key) 
     res << '</td><td style="padding-left: 15px; font-size: 12px">'
     res << changed_attr_format(changed_attributes[key], 'old') 
     res << '</td><td style="padding-left: 20px;  font-size: 12px">'
     res << changed_attr_format(changed_attributes[key], 'new') 
     res << '</td></tr>'
    rescue => e
      logger.error("Error: Some changed attributes were not recorded: #{$!}.")
    end
   end 
   res
 end
 

end
