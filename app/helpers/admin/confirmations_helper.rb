module Admin::ConfirmationsHelper


  def conf_header(conf)
          link_to_profile = link_to(conf.member.user_name, member_profile_short_url(:username => conf.member.user_name)) rescue "ERROR"
    link_to_invite = link_to(conf.invitation.name, show_invite_url(:id => conf.invitation.id, :meeting_id => (conf.meeting.id rescue nil)))
    "#{link_to_profile} #{conf_op(conf)} the Invite #{link_to_invite}"
  end

  def conf_op(conf)
    case conf.status
    when Status[:accepted]
      " has accepted "
    when Status[:approved]
        " was invited to "
    when Status[:confirmed]
        " is confirmed for "
    when Status[:declined]
        " has declined "
    when Status[:saved]
       " is watching "
    when Status[:rejected]
       " was rejected for "
    when Status[:new]
       " sent a message regarding "
    when Status[:active], Status[:expired],  Status[:modified]
       " ???  #{conf.status.name} ???? "
    else
      "ERROR: Unknown Status"
    end
  end


end
