module CalendarHelper

  def ical_link(member)
		url = subscribe_ical_url(:uuid => member.uuid)
    url.gsub!('http:', 'webcal:')
    url
  end
end
