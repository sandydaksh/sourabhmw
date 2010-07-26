class FaqSection < ActiveRecord::Base    
	 acts_as_list
	 has_many :faqs, :order => 'faqs.position', :foreign_key => 'faq_section_id'
end
