class GuestResponseController < ApplicationController
  helper :member_profiles
  layout 'guest_response'
  before_filter :login_required
  before_filter :ownership_required
  
   before_filter :setup_show_data , :only =>[:show, :select_date]
  def show
     check_render_facebook('guest_response', :wrapper)   
  end
  
  def select_date

  end
  
  private    

  def status_priority(member)
	    confirmation =  @all_confirmations.detect{|confirmation| confirmation.member.id == member.id}
	    case (confirmation.status_id rescue nil  )   # Hack ... non member don't have confirmations.
	      when Status.id_for(:confirmed)
		        0
		    when Status.id_for(:approved)
			      1
			  else
				    2
				end
  end
  
  def ownership_required
    @meeting = Meeting.find(params[:id])
    @invitation = @meeting.invitation
    if @invitation and @invitation.inviter == current_member
      return true
    else
        redirect_to show_invite_url :id => params[:id]
      return false
    end
  rescue
    redirect_to not_found_url
  end     

  def setup_show_data
	   	@meeting = Meeting.find(params[:id], :include => [:invitation, {:confirmations => {:member => {:member_profile => MemberProfile::EAGER_LOADING_CANDIDATES}}}, {:messages => [:recipients, :author]}])
	    @invitation = @meeting.invitation

	    @all_confirmations = @meeting.confirmations 

	    # Get people invited explicitely to the meeting has to be invitation here. Since confs aren't created for all meetings.
	    @all_invited_members = @invitation.invited_members

	    all_invited_members_ids = @all_invited_members.map(&:id)  
	    # Get all the confirmations for the meeting and remove the people who were invited.
	    @invited_confirmations, @not_invited_confirmations = @all_confirmations.partition{|conf|  all_invited_members_ids.include?(conf.member_id)}

	    @members_who_want_to_attend = @not_invited_confirmations.map(&:member)  

		  @members_who_want_to_attend.sort! do |x,y|
			   status_priority(x) <=> status_priority(y) 
			end  

			@all_invited_members.sort! do |x,y| 
				      status_priority(x) <=> status_priority(y) 
			end    

	    @viewer = current_member
	end

end
