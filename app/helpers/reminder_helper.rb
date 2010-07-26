module ReminderHelper
  
  # Note that we don't include a meeting_id in the snhow_invite_urls here--this is to ensure that, 
  # when you click on the link in a reminder, you don't see an old one (even if you click on the link 
  # from an old reminder email)
  
  def set_message_for(reminder, how_to_change = true)
    name = link_to(reminder.invitation.name, show_invite_url(reminder.invitation.id), :class => 'inv_name_for_reminder')
    advance = content_tag('span', reminder.advance_in_english, :class => 'orange')
    link = link_to("visit the details page for this invitation.", show_invite_url(reminder.invitation.id))
    str = "You will be sent a reminder #{advance} before #{name}."
    str << " If you'd like to change this, #{link}" if how_to_change
    str
  end
  
  def unset_message_for(invitation)
     name = link_to(invitation.name, show_invite_url(invitation.id), :class => 'inv_name_for_reminder')
    "You <span class='orange'>will not</span> receive a reminder for #{name}."
  end
  
  def update_message_for(reminder)
      advance = content_tag('span', reminder.advance_in_english, :class => 'orange')
      name = link_to(reminder.invitation.name, show_invite_url(reminder.invitation.id), :class => 'inv_name_for_reminder')
      str = "You will now be sent a reminder #{advance} before #{name}."
      str
  end

end
