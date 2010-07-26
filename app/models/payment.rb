# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#

class Payment < ActiveRecord::Base;
  has_many :invitations
  PAYMENT_OPTS = Payment.find(:all).collect { |y| [y.name, y.id] }
  COSTS_OPTS = Payment.find(:all)
  FREE_OR_NA = Payment.find_by_name('Free or NA')
end
