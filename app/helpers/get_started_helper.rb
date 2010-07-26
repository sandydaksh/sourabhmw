module GetStartedHelper

  def attend_button(meeting,viewer)
      img = button_image('accept',  :alt => "REQUEST_INVITATION",  :height => "26")
      return link_to(img, attend_url(:id => (meeting.id rescue nil)), :id => 'attend_button')
  end

  def city(inv)
    return '' if inv.address.nil?
    addr = (inv.address.airport || inv.address)
    return addr.city
  end
  
  
 def getUserName(invitation_id)
  
  @anyomonus=HiddenUserName.find_by_invitation_id(:all,:conditions => ["invitation_id = ?",invitation_id])
  
    if @anyomonus
       @pw_name= @anyomonus.private_name
    end  
end

end
