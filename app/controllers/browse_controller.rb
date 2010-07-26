 class BrowseController < ApplicationController
  layout 'new_super_search'
  before_filter :url_check
  before_filter :get_browse_state, :private_global
  helper :post_invite
  helper :invitations
  def upcoming
    new_super_search_upcoming
  end  
  
 ## Function for getting invitation according to the user's provided location.
 def new_super_search_upcoming
    @browse_state.attributes=(params)
    @search_filter = @browse_state.make_search_filter
    @feed_params = @search_filter.to_rss_params
    search_filter = @search_filter.clone
    search_filter.start_date = Time.now.utc

    if !search_filter.zip.blank? ||  !search_filter.city.blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",search_filter.zip,search_filter.city])
      rad = 25
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?
    @invitations=Invitation.search " #{search_filter.country}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :id, :sort_mode => :desc, :page => params[:page], :per_page => 10 
    if @invitations.blank?
      @invitation = Invitation.new(:recurrence_frequency => 'weekly', 
        :address => Address.new(:state => @geoip_location.state, 
          :city  => @geoip_location.city, 
          :country => @geoip_location.country))
    end
  end    
  
  def map
    render :template => "map/index"
  end

  def set_location
    if params[:value].blank?
      # The Google Bot triggers this by doing a GET for /browse/set_location.
      redirect_to browse_url
      return
    end
    loc = TextLocation.new(params[:value])
    @browse_state.city    = loc.city
    @browse_state.state   = loc.state
    @browse_state.country = loc.country
    @browse_state.zip     = loc.zip
    session[:geoip_location] = @geoip_location = loc
    @search_filter = @browse_state.make_search_filter
    if !loc.zip.blank? ||  !loc.city.blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",loc.zip,loc.city])
      rad = 25
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?
    @invitations = Invitation.search "#{loc.country}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10
  end
  
  ## Function for rendering layout for search result pages.
  def new_super_search
    setup_search_filter()
    @invitations = []
    unless @search_filter.blank? 
      # Rss should not serve up expired invites.
      @search_filter.start_time = Time.now.utc if params[:format] == 'rss'
    end
    @feed_params = @search_filter.to_rss_params     
    if params[:format] and params[:format] == 'rss'
      handle_rss() 
    else
      render :action => "new_super_search", :layout =>  'new_super_search' unless check_render_facebook('super_search')
    end
  end

  ## Function for advanced search on search result page.
  def super_search
    @browse_state.attributes=(params)
    @search_filter1 = @browse_state.make_search_filter
    
    ## Condition - when to include or exlude romance from the search list.
    if params[:search_filter].nil? || (!params[:search_filter].nil? && params[:search_filter][:romance] == "19") 
      cond = params[:search_filter][:romance].to_i if !params[:search_filter].nil? && !params[:search_filter][:romance].nil?
      cond = 19 if !params[:search_filter].nil? && params[:search_filter][:romance].nil?
      cond = 19 if params[:search_filter].nil?
    else
      cond = 0
    end
    
    ## Month validation as it should not be greater than 12.
    if !params[:search_filter].nil? && ( !params[:search_filter][:start_time].nil? || !params[:search_filter][:end_time].nil?) 
      if params[:search_filter][:start_time] && params[:search_filter][:start_time] != "MM/DD/YYYY"
        s = params[:search_filter][:start_time].split('/')
        if s[0].to_i > 12
          params[:search_filter][:start_time] = Time.now.utc
        end
      end
      
      if params[:search_filter][:end_time] && params[:search_filter][:end_time] != "MM/DD/YYYY"
        s = params[:search_filter][:end_time].split('/')
        if s[0].to_i > 12
          params[:search_filter][:end_time] = Time.now.utc
        end
      end
    end
    
    ## Condition for getting activity id range.
    if !params[:search_filter].nil? && !params[:search_filter][:purpose_id].blank?  
      p_id = params[:search_filter][:purpose_id].to_i
    elsif !params[:search_filter].nil? && params[:search_filter][:purpose_id].blank?
      p_id = 1..21
    end  
    
    ## Condition for getting purpose id range.
    if !params[:search_filter].nil? && !params[:search_filter][:activity_id].blank?  
      a_id = params[:search_filter][:activity_id].to_i
    elsif !params[:search_filter].nil? && params[:search_filter][:activity_id].blank?
      a_id = 1..14
    end  
    
    ## Condition for getting zip codes in the given radius.
    if params[:checked_locat] == "1"
      if params[:search_filter][:city] == "Atlanta" or params[:search_filter][:city] == "atlanta" or params[:search_filter][:city] == "ATLANTA"
        st = "GA"
      elsif  params[:search_filter][:city] == "Boulder" or params[:search_filter][:city] == "boulder" or params[:search_filter][:city] == "BOULDER"
        st = "CO"
      elsif  params[:search_filter][:city] == "San Diego" or params[:search_filter][:city] == "san diego" or params[:search_filter][:city] == "SAN DIEGO"
        st = "CA"
      elsif  params[:search_filter][:city] == "Dallas" or params[:search_filter][:city] == "dallas" or params[:search_filter][:city] == "DALLAS"
        st = "TX"
      elsif  params[:search_filter][:city] == "Houston" or params[:search_filter][:city] == "houston" or params[:search_filter][:city] == "HOUSTON"
        st = "TX"
      elsif  params[:search_filter][:city] == "Miami" or params[:search_filter][:city] == "miami" or params[:search_filter][:city] == "MIAMI"
        st = "FL"
      elsif  params[:search_filter][:city] == "San Francisco" or params[:search_filter][:city] == "san francisco" or params[:search_filter][:city] == "SAN FRANCISCO"
        st = "CA"
      elsif  params[:search_filter][:city] == "Portland" or params[:search_filter][:city] == "portland" or params[:search_filter][:city] == "PORTLAND"
        st = "OR"
      elsif  params[:search_filter][:city] == "San Jose" or params[:search_filter][:city] == "san jose" or params[:search_filter][:city] == "SAN JOSE"
        st = "CA"
      end
      
      if !params[:search_filter].nil? && (!params[:search_filter][:zip].blank? ||  !params[:search_filter][:city].blank?)
        if st != ""
          r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or (city = '#{params[:search_filter][:city]}' and state = '#{st}')",params[:search_filter][:zip]])
        else
          r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",params[:search_filter][:zip],params[:search_filter][:city]])
        end
        rad = params[:search_filter][:radius].to_i
        if !r.nil?
          sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
          z = ZipCode.find_by_sql(sql)
          zcids = z.collect(&:id)
        end
      else
        zcids = ""
      end
    end
    
    zcids = "" if r.nil?
    
    params[:search_filter] ||= params["amp;search_filter"]  # Hack to stop a malformed feed url from causing an exception - dave
    if params[:search_filter].nil?
      @search_filter = SearchFilter.new
    else
      @search_filter = SearchFilter.new(params[:search_filter])
    end
    
    if !params[:search_filter].nil?
      if params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @search_filter.start_time = Time.now.utc
      elsif params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @search_filter.start_time = params[:search_filter][:start_time].to_date.to_time
      elsif params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
        @search_filter.start_time = params[:search_filter][:end_time].to_date.to_time
        @search_filter.end_time = nil
      elsif params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
        if params[:search_filter][:start_time].nil? && !params[:search_filter][:start_date].nil?
          params[:search_filter][:start_time] = params[:search_filter][:start_date]
        end
        @search_filter.start_time = params[:search_filter][:start_time].to_date.to_time if !params[:format] && !params[:search_filter][:start_time].nil?
        @search_filter.start_time = Time.now.utc if !params[:format] && params[:search_filter][:start_time].nil?
        @search_filter.end_time = params[:search_filter][:end_time].to_date.to_time if !params[:search_filter][:end_time].nil? 
      end
    end
    
    if !params[:search_filter].nil?
      location = params[:search_filter][:location] ? params[:search_filter][:location] : ''
      terms = params[:search_filter][:terms] ? params[:search_filter][:terms] : ''
      person = params[:search_filter][:person] ? params[:search_filter][:person] : ''
      state = params[:search_filter][:state] ? params[:search_filter][:state] : ''
      country = params[:search_filter][:country] ? params[:search_filter][:country] : ''
      airport_id = params[:search_filter][:airport_id] ? params[:search_filter][:airport_id] : ''
      param_string = "posted #{country} #{state} #{location} #{terms} #{person} #{airport_id}" if !private_mw?
      param_string = "posted #{state} #{location} #{terms} #{person} #{airport_id}" if private_mw?
      if params[:search_filter][:virtual_f] == "0"  && params[:checked_locat] == "1"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:start_time].to_date.to_time.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :id, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:end_time].to_date.to_time,:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
      elsif params[:search_filter][:virtual_f] == "v_flag"  && (params[:checked_locat] == "0" || params[:checked_locat] == "")
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id},:conditions => {:virtual_f => "v_flag",:university_name => @univ_account}, :without => {:purpose_id => cond}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10          
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:start_time].to_date.to_time.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id}, :without => {:purpose_id => cond},:conditions => {:virtual_f => "v_flag",:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id},:conditions => {:virtual_f => "v_flag",:university_name => @univ_account}, :without => {:purpose_id => cond}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:end_time].to_date.to_time,:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id}, :without => {:purpose_id => cond},:conditions => {:virtual_f => "v_flag",:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
      else
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :id, :sort_mode => :desc, :page => params[:page], :per_page => 10  if params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:start_time].to_date.to_time.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] == "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] == "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY"
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:end_time].to_date.to_time,:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY" && !params[:search_filter][:start_time].nil? && !params[:search_filter][:end_time].nil? && !params[:format]

        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:start_time].to_date.to_time.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY" && !params[:search_filter][:start_time].nil? && params[:search_filter][:end_time].nil? && !params[:format]
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_time].to_date.to_time..params[:search_filter][:start_time].to_date.to_time.advance(:days => 1000),:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY" && !params[:search_filter][:start_time].nil? && params[:search_filter][:end_time].nil? && !params[:format]
        @invitations = Invitation.search "#{param_string}",:with => {:start_date => params[:search_filter][:start_date].to_date.to_time..params[:search_filter][:start_date].to_date.to_time,:is_public => 1,:deactivated => 0,:purpose_id => p_id,:activity_id => a_id,:zip_code_id => zcids}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10    if params[:search_filter][:start_time] != "MM/DD/YYYY" && params[:search_filter][:end_time] != "MM/DD/YYYY" && params[:format]
      end
    else
      @search_filter.start_time = Time.now.utc
      @invitations = Invitation.search "posted",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0}, :without => {:purpose_id => cond},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10 
    end
    @feed_params = @search_filter.to_rss_params 
    if params[:format]
      handle_rss()
    else
      render :action => "new_super_search", :layout =>  'new_super_search' unless check_render_facebook('super_search')
    end
  end
  
  def area_search
    area = params[:area].gsub(/[-].*/,"")
    @area = area
    area_hash = metro_areas[area]
    render(:file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found") and return if area_hash.blank?
    if(area_hash[:country] )
      area_hash[:country] = area
    else
       zip = ZipCode.find_by_city_and_state( area_hash[:city_zip], area_hash[:state_zip]).zip
    end
    area_hash[:start_time] = Date.today.strftime("%m/%d/%Y")
    area_hash[:end_time] = "MM/DD/YYYY"
    area_hash[:city] = area_hash[:city_zip]
    area_hash[:zip] = zip.zip if !zip.nil?
    area_hash[:state] = area_hash[:state_zip]
    area_hash[:stars] = 2
    params[:search_filter] = area_hash
    @search_filter = SearchFilter.new(params[:search_filter])
    if !params[:search_filter][:zip].blank? ||  !params[:search_filter][:city].blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",params[:search_filter][:zip],params[:search_filter][:city]])
      rad = 25
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?
    invitations_by_zipcodeid=Invitation.search "posted #{params[:search_filter][:country]}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :id, :sort_mode => :desc, :page => params[:page], :per_page => 10 
    invitations_by_area=Invitation.search "posted #{area}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0}, :without => {:purpose_id => 19},:conditions => {:virtual_f => "no_flag",:university_name => @univ_account}, :order => :id, :sort_mode => :desc, :page => params[:page], :per_page => 10
    
    if !invitations_by_zipcodeid.blank?
       @invitations=invitations_by_zipcodeid
     end
     
    if !invitations_by_area.blank? && invitations_by_zipcodeid.blank?
       @invitations=invitations_by_area
    end 
    render :layout => false if mobile_request?
  end
  
  
  ## Function for finding meeting from home page.
  def simple_search
    @browse_state.attributes=(params)
    @search_filter1 = @browse_state.make_search_filter
    if !params[:where].nil? && !params[:where].blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ? or state = ?",params[:where],params[:where],params[:where]])
      rad = 25
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?
    @search_filter = SearchFilter.new
    if !params[:find].nil?
      params[:what] = params[:find][:meeting] != "e.g. Business Networking" ? params[:find][:meeting] : ""
    end
    @search_filter.start_time = Time.now.utc 
    @search_filter.romance = "1"
    what = params[:what] ? params[:what] : ''
    @invitations = Invitation.search "posted #{what}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10
    render :action => 'new_super_search', :layout => 'new_super_search'
  end

  def find
    @query = params[:terms] || ''
    if !params[:where].nil? && !params[:where].blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ? or state = ?",params[:where],params[:where],params[:where]])
      rad = 25
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?
    @search_filter = SearchFilter.new
    if !params[:find].nil?
      params[:what] = params[:find][:meeting] != "e.g. Business Networking" ? params[:find][:meeting] : ""
    end
    @search_filter.start_time = Time.now.utc 
    @search_filter.romance = "1"
    what = params[:what] ? params[:what] : ''
    @invitations = Invitation.search "posted #{what}",:with => {:start_date => @search_filter.start_time..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10
    @searched = true
    render :action => 'new_super_search', :layout => 'new_super_search' unless mobile_request?
  end
  

  protected
   def handle_rss
    @pub_date = @invitations.first.updated_at rescue Time.now.last_year
    headers["Content-Type"] = "application/rss+xml"
    @feed_params.delete(:format)
    @search_url = ssearch_url(@feed_params)        
    render :template => 'feed/search', :layout => false
  end
  
   def setup_search_filter
    params[:search_filter] ||= params["amp;search_filter"]  # Hack to stop a malformed feed url from causing an exception - dave
    if params[:search_filter].nil?
      @search_filter = SearchFilter.new
      @search_filter.start_date = (Date.today + 1)
    else
      @search_filter = SearchFilter.new(params[:search_filter])
      @search_filter.start_date = Time.now.utc if params[:search_filter][:start_date] == "MM/DD/YYYY" && params[:search_filter][:end_date] == "MM/DD/YYYY"
      @searched = true unless @search_filter.blank?
    end
  end
  
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
    end
  end

  def get_browse_state
    session[:browse_state] = BrowseState.new(:category => 'all', 
      :timeframe => 'anytime',
      :city      => @geoip_location.city,
      :state     => @geoip_location.state,
      :country   => @geoip_location.country,
      :zip       => @geoip_location.zip)
    @browse_state = session[:browse_state]
  end

  def get_search_filter(terms = '')
    @search_filter = SearchFilter.get_for_terms(terms)
    return @search_filter
  end
  
  def search_for_invitations(search_filter)
    search_filter.full_text_search({:page => (params[:page]||1), :use_invitation => true}, :include => SearchFilter::INVITATION_BROWSE_INCLUDES)   
  end

  
  def make_feed_url(sf)
    # It would be cleaner to turn this into a SearchFilter instance method
    # instead of relying on being called with a search_filter instance prior
    # to full_text_search method call
    "#{ssearch_url}#{build_query_string(sf.to_params)}&format=rss"
  end
  
end
