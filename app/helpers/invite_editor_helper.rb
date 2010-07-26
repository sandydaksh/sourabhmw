module InviteEditorHelper
  
  def locked_schedule_tt_html
     %q{ Since this invite is a <b>recurring invite</b>, its schedule has been locked and cannot be modified.  If you want to change the time or 
       frequency of your meeting permanently, please create a new meeting and delete this one.   }
  end

   def mobile_time_select(name, time = Time.now)
	 hours = [ '12', ' 1', ' 2', ' 3', ' 4', ' 5', ' 6', ' 7', ' 8', ' 9', '10', '11', '12', ' 1', ' 2', ' 3', ' 4', ' 5', ' 6', ' 7', ' 8', ' 9', '10', '11' ]
	 minutes = (0...60).to_a.collect {|min| sprintf("%.2d", min) }
	 meridiem = ['AM', 'PM']
	 current_hour = time.hour
	 hour_opts = options_for_select(hours, hours[current_hour])
	 current_minute = time.min
	 minute_opts = options_for_select(minutes, minutes[current_minute])
	 am_pm = time.strftime("%p")
	 logger.error("am_mp: #{am_pm}")
	 meridiem_opts = options_for_select(meridiem, am_pm)

	 result = select_tag("#{name}[hour]", hour_opts) << ":"
	 result << select_tag("#{name}[minute]", minute_opts) << " "
	 result << select_tag("#{name}[meridiem]", meridiem_opts)
	 return result
   end
   

end
