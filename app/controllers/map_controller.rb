class MapController < ApplicationController
 # caches_action :index, :browse, :embeded

 # before_filter :set_ttl
  skip_before_filter :verify_if_facebook

 def index
	  
 end

 def embeded   
  layout = (params[:id] == 'iframe') ? 'iframe_map' : false
  render :action => :index, :layout => layout              
 end   
	
 def browse
  render :action => :index, :layout => 'browse'              
 end
 
 def home_page_map
  render :layout => false
 end
 # def update
 #      @map = Variable.new("map")
 #      @marker = GMarker.new([75.89,-42.767],:title => "Update", :info_window => "I have been placed through RJS")
 # 
 #      render :update do |page|
 #         page << @map.clear_overlays
 #         page << @map.add_overlay(@marker)
 #      end
 #   end
 # 
 #   def yahoo_map
 # 
 # 	    @map = Mapstraction.new("map_div",:yahoo)
 # 		  @map.control_init(:small => true)
 # 		  @map.center_zoom_init([40.5,-104],6)
 # 
 # 		  @invites = Meeting.find(:all, :include => [:invitation => [{:address => :zip_code}, :inviter]], :limit => 100, :order => "meetings.start_time desc").group_by(&:invitation_id)
 # 
 # 	 end

 def compute_cache_key(options = params )
  super(:action => options[:action], :id => options[:id], :controller => options[:controller])     
 end

 private
 def set_ttl
    
  response.time_to_live = 1.day
 end                 
end
