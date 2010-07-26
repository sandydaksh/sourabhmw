module GuestResponseHelper
  
  def guest_response_link(invitation)
     link_to(truncate(invitation.name, 45), guest_response_url(:id => invitation.id))
  end
  
  def mini_icon(member, even_odd = "even")
    if member.is_a?(Member) && member.member_profile && member.member_profile.picture 
      image_tag(mini_thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :class => "mini_icon", :alt => '--') 
      return(mini_thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s)) 
    
    else 
      img_type = ((even_odd == "odd") ? "dark" : "light")
      image_tag("/images/meetingwave/candy/little_guy_#{img_type}_40.gif", :class => "mini_icon #{even_odd} #{img_type}") 
      return("/images/meetingwave/candy/little_guy_#{img_type}_40.gif") 
      
    end 
  end
  
  def bg_for_row(member, klass)
      color  = ((klass == "even") ? '#eee' : '#ddd')
     str =  "background: #{color} url(#{mini_icon(member, klass)}) no-repeat;  " 
     str << "background-position: 2px 1px;"
     str
  end
  
  def close_button(conf_id, row_class)
  	script = "GuestResponse.close(#{conf_id});"
  	id = "close_#{conf_id}"
  	link_to_function(image_tag("/images/ttb/button_close_small.#{row_class}.gif"), script, :style => "display: none;", :id => id) 
  end
  
  def open_button(conf_id, row_class)
    script = "GuestResponse.open(#{conf_id});"
  	id = "open_#{conf_id}"
  	link_to_function(image_tag("/images/ttb/button_details.#{row_class}.gif"), script, :id => id) 
  end
  
  def toggle_row(txt, row_id)
    script = "GuestResponse.toggle(#{row_id});"
  	link_to_function(txt, script)
  end
  
  def most_recent_msg_txt(meeting, viewer, member)
	  member ||= viewer 
    return '' if meeting.nil?

    msg = meeting.most_recent_message(member)
    
    if msg.blank?
      return ''
    else
      res = ''
      author_name = (viewer == msg.author ?  'You' : (msg.author.user_name.capitalize_each_word rescue nil))
      if author_name
        res = content_tag('span', "#{author_name} said: ", :class => 'author')
      end
      res << truncate(msg.body, 45)    

      return res
    end     
	   

  end
  
  def author_name(author, member)
    if author == member
      return "You"
    else
      return( author.user_name rescue 'They')
    end
  end
  
  def author_class(author, member)
    if author == member
      return "you"
    else
      return "them"
    end
  end
  
  def mini_icon_img(member)
     if member.is_a?(Member) and member.member_profile and member.member_profile.picture 
        return image_tag(mini_thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :alt => '--') 
     else 
       return image_tag("/images/ttb/little_guy_brown.gif") 
     end 
   end
   
   def response_for(conf)
     if conf.nil? or conf.status == Status['new']
       return 'Invited'
     elsif conf.status.simple_name == 'Attending' and conf.meeting.expired?
       return 'Attended'
     else
       return conf.status.simple_name
     end
   end
   
   def full_list_of_acceptances_awaiting_response(invitation, current_meeting = nil)
     	confs_grouped_by_meeting_id = @invitation.current_confs_accepted.group_by(&:meeting_id)
     	confs_grouped_by_meeting_id.delete(current_meeting.id) unless current_meeting.nil?
      return '' if confs_grouped_by_meeting_id.size.zero?
     	message = "NEW ACCEPTANCES: "
     	sorted_dates = confs_grouped_by_meeting_id.keys.sort
     	links = sorted_dates.collect do |meeting_id|
     	  meeting = Meeting.find(meeting_id)   
     	  date = meeting.start_time_local
     	  confirmations = confs_grouped_by_meeting_id[meeting_id]
		  if invitation.no_pref != 1
			  date_string = date.strftime("%b %d").upcase
			  link_to(date.strftime("<span class='acceptance_awaiting'><b>#{date_string}</b></span>"), guest_response_url(:id => meeting_id)) 
		  else
			  date_string = date.strftime("%b %d").upcase
			  link_to("<span class='acceptance_awaiting'><b>No Preference</b></span>", guest_response_url(:id => meeting_id)) 
	      end
   	  end
   	  last_one = links.size - 1
   	  links.each_with_index do |link, idx|
 	      message << link
 	      if idx == last_one -1
 	        message << " and "
        elsif idx == last_one
          message << "."
        else
          message << ", "
        end
 	    end  

      return content_tag('div', message, :id => 'acceptances_awaiting_response', :class => 'acceptances_awaiting_response')
   end  
  
end
