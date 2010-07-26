module AddressesHelper
    
  def city_state_format(address) 
    if address.state.blank?
      return address.city
    else
      return "#{address.city}, #{address.state}"
    end
  end
  
  def edit_link(addr, member)
    result = ''
    if(member and member.owner(addr)) 
    	result = "[ #{link_to('Edit', edit_address_url(:id => addr.id))} ]"
    end 
    result
  end
  
  def delete_link(addr, member)
    result = ''
    if(member and member.owner(addr))
    	result = "[ #{link_to('Delete', delete_address_url(:id => addr.id), :confirm => "Are you sure you want to delete this favorite place?")} ]"
    end 
    result
  end

end
