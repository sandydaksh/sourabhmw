class MemberApproval < ActiveRecord::Base
  belongs_to :member
  belongs_to :invitation

end