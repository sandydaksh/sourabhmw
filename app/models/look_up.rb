class LookUp

  class Stars
    FOR_HOME_UPCOMING      = 5
    FOR_HOME_WAVEMAKERS    = 5
    FOR_HOME_MAP           = 3
    FOR_BROWSE_MAP         = 3
    FOR_TODAY_UPCOMING     = 3
    FOR_TOMORROW_UPCOMING  = 3
    FOR_BROWSE_UPCOMING    = 2
    FOR_GET_STARTED        = 2
    FOR_USER_HOME_UPCOMING = 2
    FOR_USER_HOME_MAP      = 2
  end

  # This is supposed to be the checkpoint through which display code that
  # displays invites or meetings gets the records it should display.
  #
  # Each method in this class corresponds to a page and section of the site.
  # For example, one method might fetch the invites that are displayed on the
  # small map *section* on the home *page*.  
  #
  # The whole reason for having this "single point of contact" is to be able to
  # control parameters in one place, rather than search all over the code for
  # where the queries are made. 
  #
  # The arity of these methods should be zero or close to it, since we want
  # this class to be the place where all parameters are defined.  If you think
  # you need a new argument, like ":limit => somenumber", then ask yourself if
  # maybe you should just create a new method that passes a different limit to
  # the underlying query.
  #
  # Methods are named like so: [objects]_for_[section]_on_[page]
  #

  class << self

    def invites_for_map_on_user_home(ids)
      Invitation.load_for_map(ids, Stars::FOR_USER_HOME_MAP)
    end

    def invites_for_map_on_home
      Invitation.find_for_map(200, :stars => Stars::FOR_USER_HOME_MAP)
    end

    def invites_for_upcoming_on_home
      invites = Invitation.home_page_invites(:stars => Stars::FOR_HOME_UPCOMING)
	  invites = invites.sort_by { |i| i.description.length }.reverse
	  return invites[0...6]
    end

    def invites_for_todays_upcoming_on_home
      invites = Invitation.home_page_invites_in_timeframe(:stars => Stars::FOR_TODAY_UPCOMING, :starting => Time.now.utc, :ending => (Time.now + 24.hours).utc)
      invites = invites.sort_by { |i| i.description.length }.reverse
      return invites[0...4]
    end

    def invites_for_tomorrows_upcoming_on_home(today_ids)
      invites = Invitation.home_page_invites_in_timeframe1(:stars => Stars::FOR_TOMORROW_UPCOMING, :starting => (Time.now + 24.hours).utc, :ending => (Time.now + 48.hours).utc, :ids => today_ids)
      invites = invites.sort_by { |i| i.description.length }.reverse
      if !invites.nil?
        return invites[0...4] 
      else
        return nil
      end  
    end
    
    ## New method for private label today's meetings on home page.         
    def invites_for_todays_upcoming_on_home_private_label(univ_name)
      invites = Invitation.home_page_invites_in_timeframe_private_label(:stars => Stars::FOR_TODAY_UPCOMING, :starting => Time.now.utc, :ending => (Time.now + 24.hours).utc,:univ_name => univ_name)
      invites = invites.sort_by { |i| i.description.length }.reverse
      return invites[0...4]
    end

    ## New method for private label tomorrow's meetings on home page.     
    def invites_for_tomorrows_upcoming_on_home_private_label(univ_name,today_ids)
      invites = Invitation.home_page_invites_in_timeframe1_private_label(:stars => Stars::FOR_TOMORROW_UPCOMING, :starting => (Time.now + 24.hours).utc, :ending => (Time.now + 48.hours).utc, :ids => today_ids,:univ_name => univ_name)
      invites = invites.sort_by { |i| i.description.length }.reverse
      if !invites.nil?
        return invites[0...4] 
      else
        return nil
      end  
    end

    def invites_for_todays_meeting_list
      invites = Invitation.home_page_invites_in_timeframe(:stars => Stars::FOR_TODAY_UPCOMING, :starting => Time.now.utc, :ending => (Time.now + 24.hours).utc)
      invites = invites.sort_by { |i| i.description.length }.reverse
      return invites
    end

	
    def invites_for_tomorrows_meeting_list()
	  
      invites = Invitation.home_page_invites_in_timeframe2(:stars => Stars::FOR_TOMORROW_UPCOMING, :starting => (Time.now + 24.hours).utc, :ending => (Time.now + 48.hours).utc)
      invites = invites.sort_by { |i| i.description.length }.reverse
      return invites
    end
	
    def invites_for_upcoming_on_fbprofile(opts =  { })
      Invitation.home_page_invites(:limit => opts[:limit])
    end

    def invites_for_upcoming_on_browse(search_filter, params)
      search_filter.stars = Stars::FOR_BROWSE_UPCOMING
      search_filter.full_text_search({:page => (params[:page]||1),:use_invitation => true}, :include => SearchFilter::INVITATION_BROWSE_INCLUDES )  
    end

    def invites_for_get_started(search_filter, params)
      search_filter.stars = Stars::FOR_GET_STARTED
      search_filter.full_text_search({:page => (params[:page]||1)}, :include => SearchFilter::BROWSE_INCLUDES)   
    end

    def invites_for_map_on_browse
      Invitation.find_for_map(200, :stars => Stars::FOR_BROWSE_MAP)
    end

    def profiles_for_wavemakers_on_home
		wm = MemberProfile.find(:all,
                         :include => [:picture, :member], 
                         :conditions => ["admin_rating = ?", Stars::FOR_HOME_WAVEMAKERS], 
                         :order => "members.id desc", :limit => 100)
		wm = wm.delete_if { |wm| wm.picture.nil?}
		return wm[0...21]
    end

    def meetings_for_upcoming_on_user_home(opts = { })
        Meeting.find_near(opts[:city], opts[:state], opts[:country], :stars => Stars::FOR_USER_HOME_UPCOMING)
    end
    
    def related_invites(meeting)

      invitation = meeting.invitation if ( Meeting === meeting )

      meeting = meeting.meetings.first if ( Invitation === meeting )
  #    meetings_hash = {}
      meetings = invitation.more_like_this({:field_names => [:name],
                              :min_doc_freq => 1, 
                                :min_term_freq => 1, 
                                :limit => 100,
                                :boost => false
                                #:append_to_query => Proc.new{|query| query.add_query(Ferret::Search::TermQuery.new(:private, "false"), :must)}
#                                :append_to_query => Proc.new{|query|                               
#                                          query.add_query(Ferret::Search::RangeQuery.new(:stars, :>= =>  "2"), :must)
#                                          }
                                      },
                              :conditions => ["events.id != ?", invitation.id]
                              )
             #                meetings = meetings.map{|m| m}
     # meetings.each{|m| meetings_hash[m.invitation_id] = m}
      #meetings.select(&:open?).sort_by(&:ferret_score).reverse[0...6]


    end

  end

end
