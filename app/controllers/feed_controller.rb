class FeedController < ApplicationController
  before_filter :private_global
  
  session :off 
  layout nil
  # All invites posted by a given user.
  def user
     @member = Member.find_by_user_name(params[:id])
      if @member.nil?
        @member = Member.find(params[:id])
      end
    @invites = @member.public_posted_invites(15)
    headers["Content-Type"] = "application/rss+xml"
  end

  # All invites posted in a given city/state.
  def city
    
  end

  # Invites that match a saved search.
  def search

  end
  
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
    end
  end
  
end
