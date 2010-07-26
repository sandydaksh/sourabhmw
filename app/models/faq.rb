class Faq < ActiveRecord::Base    
	 acts_as_list :scope => :faq_section_id
	 belongs_to :section, :class_name => "FaqSection", :foreign_key => :faq_section_id
	 
	 validates_presence_of  :question, :answer
end
