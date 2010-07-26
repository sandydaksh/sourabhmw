class ProfileWidget < ActiveRecord::Base

  belongs_to :member_profile
  has_many :profile_sections, :dependent => :destroy

  def is_html?
    return (!self.html.blank?)
  end

  def to_indexable_string
	return self.profile_sections.collect(&:to_indexable_string).join(' ')
  end
  
end