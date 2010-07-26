class EmailDomain < ActiveRecord::Base
  belongs_to :university
  belongs_to :company
end
