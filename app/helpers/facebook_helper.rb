require 'invitations_helper'
require 'browse_helper'
require 'member_helper'
require 'facebook_ext'
module FacebookHelper 
	include InvitationsHelper
  
   include BrowseHelper
   include MemberHelper   
   include TTB::FacebookCanvasHelper
   include TTB::FacebookExt

   def link_to(name,options,html_options = {})  
	    html_options.merge(:target => 'ttb')  unless html_options[:only_path] == true
      super(name, options, html_options)
   end

   def reminder_button(inv, viewer)
      r = Reminder.find_by_invitation_id_and_member_id(inv.id, viewer.id)  
     
      if(r)
         image_tag("checked.gif")
      else
         image_tag("unchecked.gif")
      end   

      ""
   end  
   
   def request_comes_from_facebook?
       true
   end
   

   def number_shown_on_profile  
	    sum = 0 
	    sum += (@my_invitations.nil? ? 0 : @my_invitations.length)
	    sum += (@upcoming_invites.nil? ? 0 : @upcoming_invites.length )
	end      
	
	def facebook_user_name(inv)
	   if(inv.inviter.social_network_user)
		      fb_name(inv.inviter.social_network_user.uid)
		 else
			   "&nbsp;"
			end
	end
        
        def cast_to_invite_and_meeting(inv)
          if(Invitation === inv)
            return inv, inv.upcoming_meeting
          elsif(Meeting === inv)
            return inv.invitation, inv
          else
            return nil, nil
          end
        end

end
