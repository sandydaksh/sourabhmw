
class SavedSearchesController < ApplicationController
 before_filter :login_required 
 before_filter :admin_required, :only => "send_email"
 
 def save_email   
  saved_search = SavedSearch.new(params[:saved_search])
  saved_search.data = params[:data].merge(:terms => params[:saved_search][:name])
  saved_search.member = current_member
  saved_search.save!
    
  render :update do |page|
   page.replace_html('save-search-form', "<p class='saved-alert'> Your meeting alert has been saved.</p>")
   page.delay(1) do 
    page.visual_effect(:fade, 'search_config')
   end
  end
 end
  
 def toggle_email
  saved_search = current_member.saved_searches.find(params[:id]) rescue nil
  if(saved_search)
   saved_search.toggle_email!      
   render :update do |page|
    new_link = link_to_remote("Email: #{saved_search.email? ? 'On' : 'Off'}", 
                                 :url => toggle_email_alert_url(:id => saved_search.id), 
                                 :html => {
                                   :id => "alert-email-#{saved_search.id}", 
                                   :class => "email-#{saved_search.email? ? 'on' : 'off'}"}) 
    page.replace( "alert-email-#{params[:id]}", new_link)
   end 
  end
 end
 
 def update_name
    saved_search = current_member.saved_searches.find(params[:id]) rescue nil
    if(saved_search)
     saved_search.name = params[:value]
     saved_search.save!
     render :text => params[:value] , :layout => false
    end
 end
  
 def delete
  saved_search = current_member.saved_searches.find(params[:id]) rescue nil
  if(saved_search)
   saved_search.destroy
   render :update do |page|
    page.replace_html("meeting-alerts", :partial => '/invitations/alerts', 
                                      :locals => { :searches => current_member.saved_searches })

   end
  end

 end
 
  def new_delete
  saved_search = current_member.saved_searches.find(params[:id]) rescue nil
  if(saved_search)
   saved_search.destroy
   render :update do |page|
    page.replace_html("meeting-alerts", :partial => '/invitations/alert_content', 
                                      :locals => { :searches => current_member.saved_searches })

   end
  end

 end
 

 def email_widget
  @search_filter = SearchFilter.new(params[:search_filter])
  @saved_search = SavedSearch.new(:name => @search_filter.a_good_name, :email => true)
 end
  
 def send_email   
  
  ss = SavedSearch.find(params[:id])
  
  ss.last_send_time -= 6.months
  
  if( ss.send_if_available() )
   email = RawEmail.find(:first, :order => "id desc")  
   @text = email.raw_email.body
   @html = ""
  # @html = email.html
  else
   @html = "Nothing to send for #{ss.name} since #{ss.last_send_time.to_s}"      
  end
  render :text => "<pre> #{@text} </pre> " + @html , :layout => false
 end
end
