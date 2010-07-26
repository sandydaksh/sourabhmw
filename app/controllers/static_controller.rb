class StaticController < ApplicationController
   layout 'static'
  before_filter :url_check
   #~ caches_page :terms_of_use
   #~ caches_page :myprivacy
   #~ caches_page :safety
   #~ caches_page :howitwork
   #~ caches_page :seeall
   
  def terms_of_use
  end

  def myprivacy
    render :layout => 'about' unless params[:format] == "mp"
  end

  def safety
    render :layout => 'about' unless params[:format] == "mp"
  end
  
  def help
     @faqs = Faq.find(:all, :order => :position, :conditions => {:faq_section_id => 1})
     render :layout => 'about' unless mobile_request?
  end
  
  def facebook_faq
        @faqs = Faq.find(:all, :order => :position, :conditions => {:faq_section_id => FaqSection.find_by_name("facebook").id})
        render :action => "help", :layout => "static_facebook"
  end
      
  def contact
    render :layout => 'about'
  end
  
  def terms_of_use
    render :layout => 'about' unless params[:format] == "mp"
  end
  
  def features
    render :layout => 'features'
  end

  def about
    render :layout => 'about'
  end
  
  def seeall
    render :layout => 'about'
  end
  
  def aboutus
    render :layout => 'about'
  end
  
  def alumninetworking
    @university = University.find(:all,:conditions => ["pulic_display = ? and data_type = ?",true,"university"])
    render :layout => 'about'
  end

  def corporationsnetworking
    @university = University.find(:all,:conditions => ["pulic_display = ? and data_type = ?",true,"company"])
    render :layout => 'about'
  end
  
  def username
    render :layout => 'about'
  end  

  def howitwork
    render :layout => 'about'
  end

  def mobile
    render :layout => 'about'
  end

end
