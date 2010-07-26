  require 'enumerator'
  require 'ostruct'
  class Admin::StatsController < ApplicationController
    layout 'admin'
    before_filter :admin_required, :setup_settings
   require ( RAILS_ROOT + '/lib/gems/googlecharts-0.1.0/lib/gchart.rb' )

    def index 
      @users_graph = open_flash_chart_object(600,300, url_for(:action => "users", :settings => params[:settings]  ), true, '/')
      @invites_graph = open_flash_chart_object(600,300, url_for(:action => "invites", :settings => params[:settings]  ), true, '/')    
      @confirmations_graph = open_flash_chart_object(600,300, url_for(:action => "confirmations", :settings => params[:settings] ), true, '/')     
      @good_graph = open_flash_chart_object(600,300, url_for(:action => "confirmed_invites", :settings => params[:settings]), true, '/')          
    end

    def setup_settings
      @settings = OpenStruct.new( params[:settings] )    
      @settings.slice ||= "30"
      @settings.member_type ||= ""
      @settings.buckets ||= "5"
      @member_type = @settings.member_type.blank? ? "All" : @settings.member_type
    end


    def users

      @verified_users = Line.new(2, '#9933CC')
      @verified_users.key('Verfied', 10)

      @deleted_users = LineHollow.new(2,5,'#CC3399')
      @deleted_users.key("Deleted",10)

      @non_verified_users = LineHollow.new(2,4,'#80a033')
      @non_verified_users.key("Non Verified", 10)

      @g = Graph.new
      setup_graph([:verified_users, :deleted_users, :non_verified_users])
      #g.set_tool_tip('#x_label# [#val#]<br>#tip#')

      @g.title("#{@member_type.capitalize} users segmented by #{@settings.slice} days", "{font-size: 20px; color: #736AFF}")
      @g.set_y_legend("Number of Users", 12, "#736AFF")

      render :text => @g.render
    end

    def invites
      @private_invites = Line.new(2, '#9933CC')
      @private_invites.key('Private', 10)

      @public_invites = LineHollow.new(2,5,'#CC3399')
      @public_invites.key("Public",10)

      @g = Graph.new
      setup_graph([:private_invites, :public_invites])
      #g.set_tool_tip('#x_label# [#val#]<br>#tip#')

      @g.title("Invites for #{@member_type.capitalize} users segmented by #{@settings.slice} days", "{font-size: 20px; color: #736AFF}")
      @g.set_y_legend("Number of Invites", 12, "#736AFF")

      render :text => @g.render
    end

    def confirmations
      @total_confirmations = Line.new(2, '#9933CC')
      @total_confirmations.key('Total', 10)

      @approved_confirmations = LineHollow.new(2,5,'#CC3399')
      @approved_confirmations.key("Pre-Approved",10)

      @accepted_confirmations = LineHollow.new(2,4,'#80a033')
      @accepted_confirmations.key("Wants To Go", 10)

      @confirmed_confirmations = LineHollow.new(2,4,'#000000')
      @confirmed_confirmations.key("Actually Going", 10)

      @g = Graph.new
      setup_graph([:total_confirmations, :approved_confirmations, :accepted_confirmations,:confirmed_confirmations])
      #g.set_tool_tip('#x_label# [#val#]<br>#tip#')

      @g.title("Confirmations for #{@member_type.capitalize} users segmented by #{@settings.slice} days", "{font-size: 20px; color: #736AFF}")
      @g.set_y_legend("Number of Users", 12, "#736AFF")

      render :text => @g.render
    end

    def confirmed_invites
      @rows = DailyStat.find_by_sql("select DATE_FORMAT(m.start_time, '%Y%m') as date, count(*) as count from confirmations as c , meetings as m where c.meeting_id = m.id and c.status_id = 120 group by date order by date  ").sort_by(&:date)
      @invites_with_attendees  = BarOutline.new(50, '#9933CC', '#8010A0')
      @invites_with_attendees.key("Invites with confirmed attendees", 10)
      max = 0 
      @rows.each do |row|
        @invites_with_attendees.add(row.count)
        max = row.count.to_i if row.count.to_i > max
      end

      @g = Graph.new
      @g.data_sets << @invites_with_attendees
      @g.set_x_labels(x_labels = @rows.map(&:date))
      links = []
      
      @rows.each do |row|
          links << url_for(:action => "confirmed_meetings", :date => row.date)
      end
      @g.set_links(links)
      max_is_labels = x_labels.length / 10
      @g.set_x_label_style(10, '#000000', 2, max_is_labels)   
      
      @g.set_y_max(max + 1)
      @g.set_y_label_steps(4)
      @g.title("Number of invites that have confirmed attendees", "{font-size: 20px; color: #736AFF}")
      @g.set_y_legend("invites", 12, "#736AFF")   
      render :text => @g.render    
    end

    
    def confirmed_meetings
        @rows = Meeting.find_by_sql("select m.* ,  DATE_FORMAT(m.start_time, '%Y%m') as date from confirmations as c , meetings as m where c.meeting_id = m.id and c.status_id = 120 and  DATE_FORMAT(m.start_time, '%Y%m') = '#{params[:date]}' group by meeting_id ")
        
    end

    def setup_graph(fields)

      fields.each do |field|
        instance_variable_set("@#{field}_values",[])
      end
      max_value = 0 
      x_labels = []
      if(@settings.member_type.blank?)
        all_stats = DailyStat.find(:all, :order => "date_id desc", :limit => ( @settings.buckets.to_i * @settings.slice.to_i ) )
      else
        all_stats = DailyStat.find(:all, :order => "date_id desc", :conditions => ["member_type = ?", @settings.member_type],  :limit => ( @settings.buckets.to_i * @settings.slice.to_i ))
      end
      all_stats.each_slice(@settings.slice.to_i) do |grouped_stats|
        x_labels << grouped_stats.first.date_id
        fields.each do |user_type|
          row = instance_variable_get("@#{user_type}_values")
          value = grouped_stats.map{|stat| stat.send(user_type)}.sum
          max_value = value if value > max_value
          row << value
        end
      end 

      fields.each do |user_type|
        instance_variable_get("@#{user_type}_values").reverse.each do |value|
          instance_variable_get("@#{user_type}").add(value)
        end      
        @g.data_sets << instance_variable_get("@#{user_type}")
      end

      @g.set_x_labels(x_labels.reverse)
      max_is_labels = x_labels.length / 10
      @g.set_x_label_style(10, '#000000', 2, max_is_labels)    
      @g.set_y_max(max_value)
      @g.set_y_label_steps(4)

    end

  end
