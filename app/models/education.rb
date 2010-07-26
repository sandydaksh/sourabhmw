# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  member_profile_id   :integer(11)   
#  school_id           :integer(11)   
#  graduation          :integer(11)   
#  id                  :integer(11)   not null
#

class Education < ActiveRecord::Base
  
  belongs_to :member_profile
  belongs_to :school
  
  validates_presence_of :school_name

  # School types
  GRADUATE_SCHOOL = "Graduate School"
  COLLEGE = "College"
  HIGH_SCHOOL = "High School"
  MIDDLE_SCHOOL = "Middle School"
  ELEMENTARY_SCHOOL = "Elementary School"
  OTHER = "Other"
  
  SCHOOL_TYPES = [ GRADUATE_SCHOOL,
                   COLLEGE,
                   HIGH_SCHOOL, 
                   MIDDLE_SCHOOL, 
                   ELEMENTARY_SCHOOL, 
                   OTHER ] 
                   
  GRADUATE = "Graduate"
  POST_GRADUATE = "Post Graduate"
  OTHER = "Other"
  
  SCHOOL_TYPES1 = [ GRADUATE,
                   POST_GRADUATE,
                   OTHER ] 
  
  def name
    self.school_name
  end
  
  def abbreviated_graduation
    return '' if graduation.blank?
    return "('#{graduation.to_s[2..4]})" rescue ''
  end
  
  def timeframe
    result = ""
    if(!(start_year.blank? or end_year.blank?))
      result << "<b>#{start_year}</b> to <b>#{end_year}</b>"
    elsif start_year
      result << "<b>#{start_year}</b>"
    elsif end_year
      result << "<b>#{end_year}</b>"
    end
    return result
  end
  
end
