class Admin::QualityController < ApplicationController
  layout 'admin'
  helper :member_profiles
  before_filter :admin_required
  before_filter :setup_score_inline
  def index
        @show_all = !(params[:show_all] == 'false')
        @min_value = params[:min_value].to_i
        @max_value = ( params[:max_value] || 1200 ).to_i

        conditions = ["( (LENGTH(name) + LENGTH(description)) between ?  and ?)", @min_value, @max_value]
        conditions[0] << "and admin_rating = -1" unless  @show_all 
		conditions[0] << " and deactivated != 1"
        @invitations = Invitation.paginate(:page => params[:page], :include => "ratings", :order => "events.created_at DESC", :conditions => conditions)	
  end

  def profiles
    params[:min_stars] ||= 3
    @invitations = Invitation.find(:all, :conditions => ["events.deactivated = 0 AND events.recurrence_frequency is not NULL AND events.recurrence_frequency != '' AND events.admin_rating > ?", params[:min_stars]], :include => [ :inviter => :member_profile])
    @member_profiles = @invitations.collect { |i| i.inviter.member_profile }.uniq.sort_by(&:admin_rating).reverse
  end

  def wavemakers
    @member_profiles = MemberProfile.find(:all, :conditions => ["admin_rating >= ? ", LookUp::Stars::FOR_HOME_WAVEMAKERS])
  end
  
  def toggle_romance
      @inv = Invitation.find(params[:id])
      @inv.purpose =  @inv.for_romance? ?  Purpose::OTHER : Purpose::ROMANCE
      @inv.save_without_validation
      div_id = "romance_maker_#{@inv.id}"
      render :update do |page|
       page.replace(div_id , :partial => "romance_maker")
       page.visual_effect(:highlight, div_id)
      end
  end
  
  def set_score_inline
   session[:score_inline] = @score_inline = ( params[:score_inline] == "true" )
   render :update do |page|
      page.replace("score_inline", :partial => "score_inline")
   end
  end
       
  def rate   
    get_class_by_name
    rateable = @rateable_class.find(params[:id])  
      
    # Delete the old ratings for current user  
    Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @rateable_class.base_class.to_s, params[:id], current_member.id])  
    rateable.add_rating Rating.new(:rating => params[:rating], :user_id => current_member.id)  
    rateable.admin_rating = params[:rating] and rateable.save_without_validation if rateable.respond_to?(:admin_rating)
    render :update do |page|  
      page.replace_html "star-ratings-block-#{rateable.id}", :partial => "rate", :locals => { :asset => rateable }  
      page.visual_effect :highlight, "star-ratings-block-#{rateable.id}"  
    end         
  end  


  def flagged
        @invitations = Invitation.paginate(:page => params[:page], 
                                           :include => ["ratings", "flaggings", "flagging_members"], 
                                           :order => "events.created_at DESC", 
                                           :conditions => ["flagged = 1 and deactivated != 1 "])	
  end

  def trash_it
    @invitation = Invitation.find(params[:id])
    @invitation.destroy
    if params["send_notification"]
      InvitationNotify.deliver_admin_deleted(@invitation)
    end
    div_id = "inv-#{@invitation.id}"
    render :update do |page|
      page.visual_effect(:fade, div_id)
      #page.remove(div_id)
    end
  end

  def clear_flag
    @invitation = Invitation.find(params[:id])
    @invitation.clear_flags!
    div_id = "inv-#{@invitation.id}"
    render :update do |page|
      page.visual_effect(:fade, div_id)
      #page.remove(div_id)
    end
  end
    
  protected  
    
  # Gets the rateable class based on the params[:rateable_type]  
  def get_class_by_name  
    bad_class = false  
    begin  
      @rateable_class = Module.const_get(params[:rateable_type])  
    rescue NameError  
      # The user is messing with the content_class...  
      bad_class = true  
    end   
      
    # This means the user is doing something funky...naughty naughty...  
    if bad_class  
      redirect_to home_url  
      return false  
    end       
    true  
  end 

  

end
