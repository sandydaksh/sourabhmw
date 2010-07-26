class Flagging < ActiveRecord::Base
  belongs_to :member
  belongs_to :invitation
  validates_presence_of :member, :invitation, :flag_reason

  SPAM = "spam"
  TEST = "test"
  OFFENSIVE = "offensive"
  TERMS = "terms"
  DISPLAY_NAMES = { SPAM => "Spam Invite", TEST => "Test/Bogus Invite", OFFENSIVE => "Offensive/Inappropriate Invite", TERMS => "Violates Terms of Service" }
  def flag_reason_display_name
    DISPLAY_NAMES[flag_reason]
  end


end
