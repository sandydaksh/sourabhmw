
class Job < ActiveRecord::Base
  
  belongs_to :member_profile

  validates_presence_of :employer_name, :title
  
  def name
    read_attribute(:title)
  end
  
  def current?
    self.end_year.blank?
  end
  
  def to_s
    append = ''
    append << employer_name unless employer_name.blank?    
    if start_year and end_year
      append << ", #{start_year.to_s} - #{end_year.to_s}"
    elsif start_year and !end_year
      append << ", since #{start_year.to_s}"
    elsif !start_year and end_year
      append << ", ended #{end_year.to_s}"
    end
    res = "#{title}"
    res << " (#{append})" unless append.blank?
    return res    
  end
  
end
