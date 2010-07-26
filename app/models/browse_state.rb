class BrowseState
  attr_accessor :category, :timeframe, :city, :state, :zip, :country

  def initialize(attrs)
    attrs.each { |k, v| self.send("#{k}=", v) }
  end

  def attributes=(attrs)
    attrs.each { |k, v| self.send("#{k}=", v) rescue nil}
  end

  def make_search_filter
   start_date, end_date = daterange_from_timeframe
   search_filter = SearchFilter.new(:category => category, 
                                    :start_date => start_date,
                                    :end_date => end_date,
                                    :city => city,
                                    :state => state,
                                    :country => country,
                                    :zip => zip,
                                    :radius => 25)
  end

  private

  def daterange_from_timeframe
    end_time = nil
    start_time = Time.now.to_date.to_time.mysql_datetime
    case timeframe
    when 'today'
      end_time = (Time.now.to_date + 1).to_time.mysql_datetime
    when 'week'
      end_time = (Time.now.to_date + 7).to_time.mysql_datetime
    when 'month'
      now = Time.now
      yyyy, mm = now.year, now.month
      d = Date.last_day_of_the_month(yyyy, mm)
      end_time = Time.gm(d.year, d.month, d.day, 23, 59, 59).mysql_datetime
    when 'year'
      now = Time.now
      end_time = Date.new(now.year, 12, 31).to_time.mysql_datetime
    end
#    " start_time >= #{start_time} AND end_time <= #{end_time}"
    return [start_time, end_time ]
  end


end
