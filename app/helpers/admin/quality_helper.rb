module Admin::QualityHelper

  def flaggers(invitation)
    flagger_links = invitation.flagging_members.collect do |member| 
      content_tag('li', link_to(member.user_name, member_profile_short_url(:username => member.user_name)))
    end
    flagger_links.uniq.join(", ") 
  end
   
  def flag_reasons(invitation)
    flag_reasons = invitation.flaggings.collect { |flagging| flagging.flag_reason }.uniq

    flag_names = flag_reasons.collect do |flag_reason|
      content_tag('li', Flagging::DISPLAY_NAMES[flag_reason], :class => flag_reason) 
    end
    flag_names.join(", ") 
  end

end
