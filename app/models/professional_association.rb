class ProfessionalAssociation < ActiveRecord::Base

  has_and_belongs_to_many :member_profiles, :join_table => 'member_profiles_professional_associations'

end