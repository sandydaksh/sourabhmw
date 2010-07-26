

module MapHelper 
	 include BrowseHelper     # Order here matters. There are naming collisions.
   include InvitationsHelper 

   def widget_right()              
	   
	
	  ' <link rel="stylesheet" href="/stylesheets/ttb/columntable.css" />    ' +
	  ' <link rel="stylesheet" href="/stylesheets/ttb/features.css" />'   +
	   render( :partial => 'shared/upcoming_for_home', :locals => {:invites => @invites.select{|inv| inv.upcoming_meeting.is_in_future? }.sort_by(&:start_time)[0..12]}  )
	end
  
end


def setup_mapstraction_markers(invites)
   invites.each do |inv_id, meetings|
      invite = meetings.sort_by(&:start_time_local).last
      logger.debug("Setting point for #{invite.address.to_google_string}")
      args = true ? invite.address.to_google_string :  [invite.address.zip_code.lat, invite.address.zip_code.lon]
      @map.marker_init(Marker.new(args,:label => invite.name, :info_bubble => (render :partial => "map/google_marker", :locals => {:invite => invite})))

   end

end
