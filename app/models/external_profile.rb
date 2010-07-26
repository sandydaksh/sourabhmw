# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  member_profile_id   :integer(11)   
#  link                :string(255)   
#  base_site           :string(255)   
#

class ExternalProfile < ActiveRecord::Base
  belongs_to :member_profile



  def link=(new_link)
    if new_link.blank?
      write_attribute(:base_site, '')
      write_attribute(:link, '')
      return  
    end
    new_link = URI::unescape(new_link)
    unescaped_link = URI::unescape(new_link)
    begin
            unescaped_link = "http://#{unescaped_link}" unless (unescaped_link.starts_with('http://') or unescaped_link.blank?)
            unescaped_link.strip! unless unescaped_link.blank?
            u = URI.parse(unescaped_link)
            write_attribute(:base_site, u.host)

    rescue
      logger.error("Error while saving ExternalProfile: #{$!}.")
      new_link =''
    end 
    write_attribute(:link, new_link)
  end

  ICON_PREFIX = '/images/ttb/profile_icons/'
  DEFAULT_ICON = "#{ICON_PREFIX}default.gif"
  def icon
    result = "<img src='"
    file_name = base_site.split('.')[-2] rescue nil
    if (file_name and File.exists?(RAILS_ROOT + '/public' + ICON_PREFIX + file_name + '.gif'))
      result << (ICON_PREFIX + file_name + '.gif')
      tooltip = "#{base_site} Profile"
    else
      result << DEFAULT_ICON 
    end
    result << "' alt='#{tooltip}' title='#{tooltip}' />"
  end

end

