class ProfileSection < ActiveRecord::Base

  belongs_to :profile_widget
  belongs_to :member_profile
  has_many :section_details, :dependent => :destroy
  validates_presence_of :name, :message => "of category can't be blank"
  
  def to_indexable_string
	return "#{name} #{self.section_details.collect(&:text).join(' ')}"
  end

end
