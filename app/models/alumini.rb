class Alumini < ActiveRecord::Base
  belongs_to :university
  validates_uniqueness_of :user_name
  validates_presence_of :user_name
  validates_presence_of :password
  validates_length_of :password, :within => 6..20, :too_long => "Please provide password length at least six character.", :too_short => "pick a longer name"

end
