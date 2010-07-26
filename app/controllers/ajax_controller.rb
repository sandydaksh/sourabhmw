class AjaxController < ApplicationController
#layout :landing

  
  def index
  
     
    #flash[:notice] = "Invalid User/Password"
	
    what = params[:what]
	
	#user = User.find_by_username(username) 
    if what.empty?  
		render :text => "Please type something."
	end
	
	@matches = MeetingInterest.find(:all, :select => "distinct interest", :conditions =>["interest LIKE ?","#{what}%"] )
	
	if @matches.empty?
	render :text => "No matches found."
	#else
	#render :partial => '/shared/match',:collection => @matches 
	
	
	#render :partial => 'ajax/match',:collection => @matches 
	#redirect_to :action => 'match',:collection => @matches 
	#redirect_to :controller=>'ajax',:action => 'match',:collection => @matches
	
	
	
	#render :text => "No matches yet"
	#@matches.each do |record|
    
	#render :text => "record"
	
    #end 	
	
	#render :text => "Matches found"
	
	
	
    end	
    end	 
	
	def match
	#render :text => "Inside match"
  end
	
  
end
