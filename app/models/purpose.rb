# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  category            :string(255)   
#

class Purpose < ActiveRecord::Base;
  has_many :invitations
  PURPOSE_OPTS = [ ['Please select', ''] ]
  Purpose.find(:all, :order => 'position, name', :conditions => [ 'position IS NOT NULL']).each { |p| PURPOSE_OPTS << [p.name, p.id] }
  @@ids_for_categories = { }
  OTHER = Purpose.find(:first, :conditions => 'name = "Other"')
  ROMANCE = Purpose.find(:first, :conditions => 'name = "Romance"')
  def self.ids_for_category(cat)
    @@ids_for_categories[cat] ||= self.find(:all, :conditions => [ 'category = ?', cat]).collect { |p| p.id }
    return @@ids_for_categories[cat]
  end


end
