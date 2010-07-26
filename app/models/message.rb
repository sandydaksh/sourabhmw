# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  created_at          :datetime      
#  author_id           :integer(11)   
#  invitation_id       :integer(11)   
#  parent_id           :integer(11)   
#  subject             :string(255)   
#  body                :string(255)   
#

class Message < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  
  belongs_to :invitation
  belongs_to :meeting
  belongs_to  :author,
              :class_name => 'Member',
              :foreign_key => 'author_id'

  has_many    :replies,
              :class_name => 'Message',
              :foreign_key => 'parent_id'
             
  has_and_belongs_to_many  :recipients,
                           :class_name => 'Member',                           
                           :join_table => 'messages_recipients'
                           
  has_and_belongs_to_many  :non_members,
                           :join_table => 'messages_non_members'

  def body=(body)
     write_attribute('body', clean_text(body))
  end

  def subject=(subject)
     write_attribute('subject', clean_text(subject))
  end

  def clean_text(txt)
     return (txt.nil? ? nil : txt.strip_tags)
  end

end
