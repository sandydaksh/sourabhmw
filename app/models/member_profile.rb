class MemberProfile < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
      acts_as_rateable  

 
  belongs_to  :member
  has_one :picture
  
  has_many :educations
  has_many :high_schools,       :class_name => 'Education', :conditions => "school_type = '#{Education::HIGH_SCHOOL}'"
  has_many :middle_schools,     :class_name => 'Education', :conditions => "school_type = '#{Education::MIDDLE_SCHOOL}'"
  has_many :elementary_schools, :class_name => 'Education', :conditions => "school_type = '#{Education::ELEMENTARY_SCHOOL}'"
  has_many :graduate_schools,   :class_name => 'Education', :conditions => "school_type = '#{Education::GRADUATE_SCHOOL}'"
  has_many :colleges,           :class_name => 'Education', :conditions => "school_type = '#{Education::COLLEGE}'"
  has_many :other_schools,      :class_name => 'Education', :conditions => "school_type = '#{Education::OTHER}'"
  alias :others :other_schools
  
  has_many :graduates,   :class_name => 'Education', :conditions => "school_type = '#{Education::GRADUATE}'"
  has_many :post_graduates,           :class_name => 'Education', :conditions => "school_type = '#{Education::POST_GRADUATE}'"
  has_many :others,      :class_name => 'Education', :conditions => "school_type = '#{Education::OTHER}'"
  
 
  has_many :schools, :through => :educations
  has_many :jobs  
  has_many :employers, :through => :jobs
  has_many :meeting_interests
  has_many :external_profiles
  
  has_many :profile_widgets, :dependent => :destroy
  has_one :meeting_interests_widget, :class_name => 'ProfileWidget', :conditions => " widget_partial = 'meeting_interests' "
  has_one :employment_widget, :class_name => 'ProfileWidget', :conditions => " widget_partial = 'employment' "
  has_one :educations_widget, :class_name => 'ProfileWidget', :conditions => " widget_partial = 'educations' "
  has_one :personal_interests_widget, :class_name => 'ProfileWidget', :conditions => " widget_partial = 'personal' "
  has_many :user_widgets, :class_name => 'ProfileWidget', :conditions => " widget_partial = 'user'"
  
  EAGER_LOADING_CANDIDATES = [ :picture, :jobs, :educations, :external_profiles]

  composed_of :tz,
              :class_name => 'TimeZone',
              :mapping => %w(time_zone name)


  ATTRS_BY_TYPE = { :employment => [ 'jobs', 'industries',  'professional_associations'],
                    :personal => [ 'military_services', 'birth_place', 'hometown', 'from_country', 
                                    'languages', 'marital_status', 'religion', 'birthdate', 
                                    ]                 
                      }

  GENDER_OPTS = { 'Male' => 'm', 'Female' => 'f', "I'd rather not say" => 'na'}
  def personal_attributes
    attrs = ATTRS_BY_TYPE[:personal].collect do |attr|
      self.send(attr)
    end
    return attrs.compact
  end
  
  def personal_attributes_blank?
     if self.personal_attributes.blank? 
        return true
      else
       non_blank = self.personal_attributes.detect { |pa| !pa.blank? }
       return non_blank.nil?
      end
  end
  
  def external_profiles_blank?
    if self.external_profiles.blank? 
      return true
    else
     non_blank = self.external_profiles.detect { |ep| !ep.link.blank? }
     return non_blank.nil?
    end
  end
  
  def personal_attributes_errors?
    attrs = ATTRS_BY_TYPE[:personal].collect do |attr|
       return true if self.errors.on(attr)
    end
    return false
  end
  
  def birthdate=(d)
    if d == 'MM/DD/YYYY'
      write_attribute(:birthdate, nil)
    else
      write_attribute(:birthdate, d)
    end
  end
  
  def city_state(prefix)
    ci = read_attribute("#{prefix}_city")
    st = read_attribute("#{prefix}_state")
    return '' if (ci.blank? and st.blank?) 
    if ci.blank?
      return "(#{st})"
    elsif st.blank?
      return "(#{ci})"
    else
      return "(#{ci}, #{st})"
    end
  end
  
  def abbr_grad(year)
    return '' if year.blank?
    return "('#{year.to_s[2..4]})" rescue ''
  end
  

  def current_job
    jobs = self.jobs.select { |j| j.end_year.blank? }
    return jobs.empty? ? nil : jobs.first
  end
  
  def previous_jobs
    self.jobs.select { |j| !j.end_year.blank? }
  end
  
  IGNORE_ATTRS = ['time_zone', 'id', 'member_id', 'gender' ]
  
  def pretty_empty?(min_attrs = 4)
    completed_attrs = 0
    attributes.each do |key, val|
      if (!IGNORE_ATTRS.include?(key) and !val.blank?)
          completed_attrs += 1
      end
    end
    completed_attrs += self.educations.size
    completed_attrs += self.jobs.size
    completed_attrs += self.meeting_interests.size
    return (completed_attrs <= min_attrs)
  end

  def filled_in?
	return (not pretty_empty?)
  end

  def jobs=(jobs)
    jobs.each_with_index do |attr, i|
      attr.each_pair { |k,v| attr[k] = clean_text(v) }
      j = self.jobs[i] ? self.jobs[i] : Job.new(attr)
      j.new_record? ? self.jobs << j : j.update_attributes(attr)
    end
  end

  def to_indexable_string
	result = ''
	result << educations.collect{|e| " #{e.school_name} in #{e.location} "}.join(', ') unless educations.blank?
	result << jobs.collect{|j| " #{j.title} at #{j.employer_name} in #{j.location} "}.join(', ') unless jobs.blank?
	result << meeting_interests.collect{|mi| " #{mi.interest} "}.join(', ') unless meeting_interests.blank?
	result << profile_widgets.collect(&:to_indexable_string).join(', ') unless profile_widgets.blank?
	result << personal_attributes.join(" ") 
    result << " " << member.user_name << " " << member.user_name.sub("_", " ") << member.user_name.sub(/\d+/, " ") unless (member.blank? or member.user_name.blank?)
	result
  end
  
  def clean_text(txt)
     return (txt.nil? ? nil : txt.strip_tags)
  end
  
  def after_save
    if(user = self.member.social_network_user rescue nil)  
      user.city = self.current_city if(user.city.blank?)
      user.state = self.current_state if(user.state.blank?)
      user.country = self.current_country if(user.country.blank?)
      user.save
    end
  end

end
