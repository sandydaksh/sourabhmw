class HelpBubblesController < ApplicationController
  skip_before_filter :verify_if_facebook
  HELP_BUBBLES = {
    "browse/super_search" =>  [
      { :logged_in => true,
	    :logged_out => false,
        :config => {
             :anchor => "search_button",
             :arrow => "top_left",
             :title => "Create a Meeting Alert", 
             :content => "To create a Meeting Alert, first enter some search criteria and click the SEARCH button.", 
             :width => 215, 
             :height => 50, 
             :offsetY => 30,
             :offsetX => 25,
			 :delay => 1.5
          }
      },
        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "meeting_alerts_button",
              :arrow => "right_top",
              :width => 290, 
              :height => 80, 
              :title => "Create a Meeting Alert", 
              :content => "Now create a Meeting Alert for this search by clicking on the Meeting Alerts button and saving the search as a Meeting Alert and Meeting Wave will notify you when new invites get posted meeting this search criteria. It's easy!",
              :offsetY => -75,
              :offsetY_IE => -35,
              :offsetX => -323,
			  :showEffectOptions => { :direction => 'top-right'},
			  :hideEffectOptions => { :direction => 'top-right'},
              :hideOnClick => [ 'refine-link', 'meeting_alerts_button']  # IDs of elements which, when clicked, should make this tooltip go away. 
        }
      },
        { :logged_in => false,
		  :logged_out => true,
          :config => {
             :anchor => "search_button",
             :arrow => "top_left",
             :title => "Create a Meeting Alert",
             :content => "Become a <a href='/signup'>registered member</a> to create your own Meeting Alerts and you'll be notified by email when new invites are posted meeting your search criteria.",
             :width => 215,
             :height => 80,
             :offsetY => 30,
             :offsetX => 25,
			 :delay => 1.5
        }
      }
    ],

    "invitations/myinvitations" => [
        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "my_contacts",
              :arrow => "top_left",
              :width => 195,
              :height => 65,
              :title => "Import Your Contacts", 
              :content => "You can import your contacts from other sites such as Gmail, Hotmail, Yahoo! and Linkedin using our <a href='/contacts/import'>contact importer</a>.",
              :offsetY => 25,
              :offsetX => 30
        }
      },
        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "upcoming-tab",
              :arrow => "bottom_left",
              :width => 370,
              :height => 80,
              :title => "Before You Attend...",
              :content => "MeetingWave is not an event site. Meetings are only confirmed when there's at least one request to attend that is approved by the member who posted the Invite. See <a href='http://www.meetingwave.com/blog/2008/10/28/meetingwave-it%E2%80%99s-not-an-event-site-confirmation-usually-required'>our MW is Not an Event Site blog article</a>. Please don't show up unless the other member has approved your request to attend.",
			  :showEffectOptions => { :direction => 'bottom-left'},
			  :hideEffectOptions => { :direction => 'bottom-left'},
              :offsetY => -120,
              :offsetX => 30,
			  :delay => 0.5
        }
      },
#        { :logged_in => true,
#		  :logged_out => false,
#          :config => {
#              :anchor => "my-meeting-alerts",
#              :arrow => "bottom_left",
#              :width => 205,
#              :height => 80,
#              :title => "Meeting Alerts",
#              :content => "Set up a Meeting Alert or RSS feed in <a href='/ssearch'>Advanced Search</a> and be notified by email when a new Public Invite is posted that meets your interests.",
#			  :showEffectOptions => { :direction => 'bottom-left'},
#			  :hideEffectOptions => { :direction => 'bottom-left'},
#              :offsetY => -120,
#              :offsetX => 30,
#			  :delay => 1.5
#        }
#      },
#	  { :logged_in => true,
#		:logged_out => false,
#          :config => {
#              :anchor => "profile-button",
#              :arrow => "bottom_left",
#              :width => 245,
#              :height => 80,
#              :title => "Create a Profile",
#              :content => "Update your profile page to make it easier to make valuable connections. A complete profile will help you find the right people to meet, and help others decide whether to meet with you.",
#              :offsetY => -130,
#              :offsetX => 5,
#			  :showEffectOptions => { :direction => 'bottom-left'},
#			  :delay => 3.0
#			}
#		},

    ],
    "invitations/index" => [
#        { :logged_in => true,
#		  :logged_out => true,
#          :config => {
#              :anchor => "headbar",
#              :arrow => "top_left",
#              :width => 335,
#              :height => 95,
#              :title => "Before You Attend...",
#              :content => "MeetingWave is not an event site. Meetings are only confirmed when there's at least one request to attend that is approved by the member who posted the Invite. See <a href='http://www.meetingwave.com/blog/2008/10/28/meetingwave-it%E2%80%99s-not-an-event-site-confirmation-usually-required'>our MW is Not an Event Site blog article</a>. Please don't show up unless the other member has approved your request to attend.",
#              :offsetY => 30,
#              :offsetX => 185,
#			  :showEffectOptions => { :direction => 'top-left'},
#			  :hideEffectOptions => { :direction => 'top-left'},
#			  :delay => 3.0
#        }
#      },
#        { :logged_in => true,
#		  :logged_out => true,
#          :config => {
#              :anchor => "post-invite-nav-button",
#              :arrow => "bottom_right",
#              :width => 265,
#              :height => 65,
#              :title => "Post an Invite!",
#              :content => "Try posting an Invite today. You can describe who you want to meet with or the purpose of the meeting. You decide whether the meeting occurs and who can attend.",
#              :offsetY => -115,
#              :offsetX => -250,
#			  :showEffectOptions => { :direction => 'bottom-left'},
#			  :hideEffectOptions => { :direction => 'bottom-left'},
#			  :delay => 2.5
#        }
#      }

    ],

    "post_invite/new" => [
        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "whotab",
              :arrow => "left_bottom",
              :width => 290,
              :height => 50,
              :title => "Invite a Friend",
              :content => "If you are shy about meeting new people, invite a friend to come along and network together. You don't have to network alone!",
              :offsetY => -50,
              :offsetX => 92,
			  :showEffectOptions => { :direction => 'top-left'},
			  :delay => 0.5
        }
      },
#		{ :logged_in => true,
#		  :logged_out => false,
#          :config => {
#              :anchor => "whentab",
#              :arrow => "left_bottom",
#              :width => 300,
#              :height => 50,
#              :title => "Flexible?",
#              :content => "If the time or location is flexible, indicate that in your Public Invite and confirm the final time/place with the members who accept your invite.",
#              :offsetY => -50,
#              :offsetX => 92,
#			  :showEffectOptions => { :direction => 'bottom-left'},
#			  :delay => 1
#        }
#      },
        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "postinvite-button",
              :arrow => "right_bottom",
              :width => 255,
              :height => 35,
              :title => "Please Note",
              :content => "You will need to approve each acceptance to confirm your meeting is on.",
              :offsetY => -40,
              :offsetX => -284,
			  :showEffectOptions => { :direction => 'bottom-right'},
			  :delay => 2
        }
      },
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "meeting-description",
              :arrow => "top_left",
              :width => 340,
              :height => 140,
              :title => "Describe Your Ideal Invitee",
              :content => "Describe the type of people you want to meet or the purpose of your meeting. Ask other members to create a Profile before accepting your Public Invites. Suggest they add a link to another site such as LinkedIn or Facebook. Also, ask that they provide their email address with their acceptance to facilitate communications.  If the time or location is flexible, indicate that in your Public Invite and confirm the final time/place with the members who accept your invite.",
              :offsetY => 10,
              :offsetX => 80,
			  :showEffectOptions => { :direction => 'top-left'},
			  :delay => 1.5
        }
      },

    ],

    "browse/upcoming" => [
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "browse_invites_1",
              :arrow => "top_left",
              :width => 300,
              :height => 95,
              :title => "Please note...",
              :content => "MeetingWave is not an event site. Meetings are only confirmed when there's at least one request to attend that is approved by the member who posted the Invite. See <a href='http://www.meetingwave.com/blog/2008/10/28/meetingwave-it%E2%80%99s-not-an-event-site-confirmation-usually-required'>our MW is Not an Event Site blog article</a>. Please don't show up unless the other member has approved your request to attend.",
              :offsetY => 20,
              :offsetX => 15,
			  :showEffectOptions => { :direction => 'top-left'},
			  :delay => 1.5
			}
		},
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "advanced-search-button",
              :arrow => "top_left",
              :width => 280,
              :height => 95,
              :title => "Find a Specific Invite",
              :content => "Did you know you can search Public Invites by keyword, location, purpose or time, including by Profile content of those posting Public Invites? Search for Public Invites posted by fellow alumni or individuals from a specified company.",
              :offsetY => 20,
              :offsetX => 15,
			  :showEffectOptions => { :direction => 'top-left'},
			  :delay => 1.5
			}
		}

	],
    "invitations/show" => [
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "attend-on-button",
              :arrow => "right_top",
              :width => 240,
              :height => 50,
              :title => "Go Ahead!",
              :content => "You can include a note with your acceptance if you have a question or like to propose a different time or place.",
              :offsetY => -25,
              :offsetX => -270,
			  :showEffectOptions => { :direction => 'top-right'},
              :hideOnClick => [ 'attend-on-button' ],  # IDs of elements which, when clicked, should make this tooltip go away.
			  :delay => 1.0
			}
		},
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "forward-button",
              :arrow => "top_left",
              :width => 180,
              :height => 50,
              :title => "Tell a Friend...",
              :content => "Forward interesting Public Invites to friends with a simple click of a button.",
              :offsetY => 20,
              :offsetX => 15,
			  :showEffectOptions => { :direction => 'top-left'},
              :hideOnClick => [ 'forward-button' ],  # IDs of elements which, when clicked, should make this tooltip go away.
			  :delay => 1.5
			}
		},
#		{ :logged_in => true,
#		  :logged_out => false,
#          :config => {
#              :anchor => "select_another_date",
#              :arrow => "left_top",
#              :width => 280,
#              :height => 35,
#              :title => "See Other Dates",
#              :content => "This is a recurring invite. Select another date if this date doesn’t work for you.",
#              :offsetY => -35,
#              :offsetX => 175,
#			  :showEffectOptions => { :direction => 'top-left'},
#              :hideOnClick => [ 'select_another_date' ],  # IDs of elements which, when clicked, should make this tooltip go away.
#			  :delay => 2.0
#			}
#		},
#		{ :logged_in => true,
#		  :logged_out => false,
#          :config => {
#              :anchor => "profile-button",
#              :arrow => "bottom_left",
#              :width => 245,
#              :height => 80,
#              :title => "Create a Profile",
#              :content => "Create a Profile with some background information before posting or accepting a Public Invite. You don’t have to disclose your full name or identity, but can remain anonymous if you choose.",
#              :offsetY => -130,
#              :offsetX => 5,
#			  :showEffectOptions => { :direction => 'bottom-left'},
#			  :delay => 3.0
#			}
#		},
#		{ :logged_in => true,
#		  :logged_out => false,
#          :config => {
#              :anchor => "reminder_settings",
#              :arrow => "top_left",
#              :width => 205,
#              :height => 110,
#              :title => "Reminders",
#              :content => "Set up a default reminder in your <a href='/myaccount'>Account Settings</a> and change the reminder time for any individual meeting. Reminder, the meeting is only confirmed if your acceptance is approved by the member who posted the invite.",
#              :offsetY => 70,
#              :offsetX => 30,
#			  :showEffectOptions => { :direction => 'top-left'},
#			  :delay => 4.0
#			}
#		},

        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "post-invite-nav-button",
              :arrow => "bottom_left",
              :width => 265,
              :height => 65,
              :title => "Post an Invite!",
              :content => "Try posting an Invite today. You can describe who you want to meet with or the purpose of the meeting. You decide whether the meeting occurs and who can attend.",
              :offsetY => -115,
              :offsetX => 30,
			  :showEffectOptions => { :direction => 'bottom-left'},
			  :hideEffectOptions => { :direction => 'bottom-left'},
			  :delay => 2.5
        }
      },

        { :logged_in => false,
		  :logged_out => true,
          :config => {
              :anchor => "post-invite-nav-button",
              :arrow => "top_left",
              :width => 265,
              :height => 65,
              :title => "Post an Invite!",
              :content => "Try posting an Invite today. You can describe who you want to meet with or the purpose of the meeting. You decide whether the meeting occurs and who can attend.",
              :offsetY => 15,
              :offsetX => 30,
			  :showEffectOptions => { :direction => 'bottom-left'},
			  :hideEffectOptions => { :direction => 'bottom-left'},
			  :delay => 2.5
        }
      }

	],
	 "member_profiles/edit" => [
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "column_A",
              :arrow => "right_top",
              :width => 240,
              :height => 50,
              :title => "Move It",
              :content => "You can move your profile boxes around by clicking and dragging on the orange move icon <img src='/images/meetingwave/buttons/orange_move_icon.gif' />.",
              :offsetY => -25,
              :offsetX => -260,
			  :showEffectOptions => { :direction => 'top-right'},
			  :hideEffectOptions => { :direction => 'top-right'},
			  :delay => 1.0
			}
		},
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "my_invites_list",
              :arrow => "left_top",
              :width => 220,
              :height => 80,
              :title => "Export Your Invites",
              :content => "Easily export your Public Invites to another site (e.g., your blog, Ning page, etc.) using the simple <a href='/widget_config'>widget-builder</a> on your profile page that lets you customize what it will look like.",
              :offsetY => -20,
              :offsetX => 130,
			  :showEffectOptions => { :direction => 'top-left'},
			  :hideEffectOptions => { :direction => 'top-left'},
			  :delay => 1.0
			}
		},
	],

	 "map/browse" => [
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "advanced-search-button",
              :arrow => "top_left",
              :width => 240,
              :height => 65,
              :title => "Please Note",
              :content => "Not all invites can be displayed on the MeetingWave map. Please also perform an Advanced Search in your area to find any Public Invites of interest.",
              :offsetY => 15,
              :offsetX => 10,
			  :showEffectOptions => { :direction => 'top-left'},
			  :hideEffectOptions => { :direction => 'top-left'},
			  :delay => 1.0
			}
		},
		{ :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "bottom-logo",
              :arrow => "bottom_left",
              :width => 290,
              :height => 105,
              :title => "Meetings, Not Events!",
              :content => "MeetingWave is not an event site. Meetings are only confirmed when there's at least one request to attend that is approved by the member who posted the Invite. See <a href='http://www.meetingwave.com/blog/2008/10/28/meetingwave-it%E2%80%99s-not-an-event-site-confirmation-usually-required'>our MW is Not an Event Site blog article</a>. Please don't show up unless the other member has approved your request to attend.",
              :offsetY => -220,
              :offsetX => 100,
			  :showEffectOptions => { :direction => 'bottom-left'},
			  :hideEffectOptions => { :direction => 'bottom-left'},
			  :delay => 1.0
			}
		},
	],

	 "member_profiles/show" => [
        { :logged_in => false,
		  :logged_out => true,
          :config => {
              :anchor => "post-invite-nav-button",
              :arrow => "top_left",
              :width => 265,
              :height => 65,
              :title => "Post an Invite!",
              :content => "Try posting an Invite today. You can describe who you want to meet with or the purpose of the meeting. You decide whether the meeting occurs and who can attend.",
              :offsetY => 15,
              :offsetX => 30,
			  :showEffectOptions => { :direction => 'bottom-left'},
			  :hideEffectOptions => { :direction => 'bottom-left'},
			  :delay => 2.5
        }
      },

        { :logged_in => true,
		  :logged_out => false,
          :config => {
              :anchor => "post-invite-nav-button",
              :arrow => "bottom_left",
              :width => 265,
              :height => 65,
              :title => "Post an Invite!",
              :content => "Try posting an Invite today. You can describe who you want to meet with or the purpose of the meeting. You decide whether the meeting occurs and who can attend.",
              :offsetY => -115,
              :offsetX => 30,
			  :showEffectOptions => { :direction => 'bottom-left'},
			  :hideEffectOptions => { :direction => 'bottom-left'},
			  :delay => 2.5
        }
      }
	 ]

  }

 

  def bubbles
    key = "#{params[:bcont]}/#{params[:bact]}"   
    bubbles = HELP_BUBBLES[key]
    if bubbles
      bubbles_to_render = []
      bubbles.each do |bubble|
		unless bubble_closed?(bubble[:config])
		  if((current_member.nil? and bubble[:logged_out]) or (current_member and bubble[:logged_in])) 
			bubbles_to_render << bubble[:config]
		  end
 	    end
      end
      render :json => bubbles_to_render
      return
    end
    render :json => []
  end

  
  
  
  #################
  
   def close
   #  We are just going to toss it in the session for now.
   key = "#{params[:bcont]}-#{params[:bact]}-#{params[:banch]}"
   
   bubble_store[key] = true
   current_member.save if current_member
   render :nothing => true
   
  end
  
  private
  
  def bubble_store
      if(current_member)
                current_member.closed_bubbles
      else
                  ( session[:closed_bubbles] ||= Hash.new )

      end
   
  end
  def bubble_closed?(bubble)
      key = "#{params[:bcont]}-#{params[:bact]}-#{bubble[:anchor]}"

      bubble_store[key]
  end

end
