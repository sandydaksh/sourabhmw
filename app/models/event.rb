# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  description         :text          
#  start_time          :datetime      
#  end_time            :datetime      
#  created_at          :datetime      
#  updated_at          :datetime      
#  class               :string(255)   
#  parent_id           :integer(11)   
#  member_id           :integer(11)   
#  state               :string(255)   
#  time_zone           :string(255)   
#  purpose_id          :integer(11)   
#  activity_id         :integer(11)   
#  payment_id          :integer(11)   
#  minimum_invitees    :integer(11)   
#  maximum_invitees    :integer(11)   
#  test_data           :boolean(1)    
#  step                :string(255)   default(Done)
#  open                :boolean(1)      
#  address_id          :integer(11)   
#  draft_status        :string(10)    default(new)
#

class Event < ActiveRecord::Base
   #  acts_as_ferret :fields =>  [ 'name', 'description' ]
  def parent
      self.class.find(parent_id)
  end

  def current?
    self.start_time >= Time.now
  end
  
  def oneday?
    self.start_time.to_date == self.start_time.to_date
  end

  def past?
    self.start_time < Time.now
  end

protected
  def before_destroy
    self.class.delete_all "parent_id = #{id}" 
  end
end
