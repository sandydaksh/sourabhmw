# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  username            :string(255)   
#  email               :string(255)   
#  deleted_at          :datetime      
#  num_invites         :integer(11)   
#

class DeletedAccount < ActiveRecord::Base
end
