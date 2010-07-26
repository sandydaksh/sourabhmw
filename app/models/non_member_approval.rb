class NonMemberApproval < ActiveRecord::Base
  belongs_to :non_member
  belongs_to :invitation
end