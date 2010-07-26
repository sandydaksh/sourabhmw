class FacebookerFeedPublisher < Facebooker::Rails::Publisher
  
  def post_invite_template
    about_url = facebook_about_page_url()
    short_story_template("{*actor*} posted an invite via #{link_to("MeetingWave", about_url )}.","{*image_link*} {*link*}")      
    full_story_template("{*actor*} posted an invite via #{link_to("MeetingWave", about_url )}.", t_body())
    one_line_story_template("{*actor*} posted an invite via #{link_to("MeetingWave", about_url )}.")
  end
  
   def post_invite(user, invitation)
    FacebookerFeedPublisher.register_post_invite unless Facebooker::Rails::Publisher::FacebookTemplate.find(:first , :conditions => "template_name like '%post_invite%'")

    send_as :user_action
    from(user)
    data({:image_link => announce_image_link ,
        :link => "#{link_to(invitation.name, facebook_show_invite_url(:id => invitation, :canvas => true, :post_invite_news => true))}",
        :description => invitation.description   })
  end
  
   def confirmation_template
    about_url = facebook_about_page_url()
    title = "{*actor*} {*action*} #{link_to("MeetingWave", about_url )} meeting."
    short_story_template(title,"{*image_link*} {*link*}")
      
    full_story_template(title, t_body)
    one_line_story_template(title)
   end
   
  def confirmation(user, confirmation)
    FacebookerFeedPublisher.register_post_invite unless Facebooker::Rails::Publisher::FacebookTemplate.find(:first , :conditions => "template_name like '%confirmation%'")

    send_as :user_action
    title_base = confirmation.attending? ? "is attending a public" : "wants to a attend a public"
    invitation = confirmation.invitation
    from(user)

    data({:image_link => announce_image_link ,
        :link => "#{link_to(invitation.name, facebook_show_invite_url(:id => invitation, :canvas => true, :confirmed_invite_news => true))}",
        :description => invitation.description ,
         :action => title_base      })
  end
  
  def announce_image_link
    link_to(image_tag("fb/announce_75.gif?v6", :style => "margin:3px;"), facebook_about_page_url(:only_path => false))
  end
  
  def t_body
     "<div style='float:left;'>{*image_link*}</div> <div style='margin:3px;'>{*link*} <p>{*description*}</p></div>"
  end
end
