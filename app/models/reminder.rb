# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  invitation_id       :integer(11)
#  confirmation_id     :integer(11)
#  member_id           :integer(11)
#  advance             :integer(11)
#
class Reminder < ActiveRecord::Base
   belongs_to :member
   belongs_to :invitation
   before_save :update_send_before 
   attr_accessor :dont_update_send_before

   ADVANCE_OPTS = [ ["15 minutes", 900],
   ["20 minutes", 1200],
   ["25 minutes", 1500],
   ["30 minutes", 1800],
   ["45 minutes", 2700],
   ["1 hour"    , 3600],
   ["2 hours"   , 7200],
   ["3 hours"   , 10800],
   ["1 day"     , 86400],
   ["2 days"    , 172800],
   ["1 week"    , 604800] ]
   ADVANCES_IN_ENGLISH = Hash.new
   ADVANCE_OPTS.each { |eng_and_numeric| ADVANCES_IN_ENGLISH[eng_and_numeric[1]] = eng_and_numeric[0] }

   def advance_in_english
      return ADVANCES_IN_ENGLISH[self.advance]
   end

   def update_send_before
      next_meeting = invitation.next_meeting
      self.send_before = next_meeting - advance  unless self.dont_update_send_before
   end

   # This is meant to be run by script/runner every few minutes.
   NEXT_UPDATE_CHUNK = 100
   def self.send_all_reminders(for_real = false)
      max_records = self.count
      update_records = 0
      number_sent = 0
      while(update_records < max_records) do
         reminders = self.find(:all, :conditions => [ "sent != 1 and send_before < ?", Time.now.utc ],
         :include => :invitation,
         :limit => NEXT_UPDATE_CHUNK,
         :offset => update_records)
         update_records += NEXT_UPDATE_CHUNK
         ## Remove reminders for meetings that have no attendees
         reminders = reminders.reject { |r| r.invitation.upcoming_meeting.confirmations.empty? rescue true }
         reminders.each do |reminder|
            email = reminder.member.email rescue "Unknown"      
            invitation = reminder.invitation
            begin
               if(for_real)
                  logger.error("Sending reminders for for #{invitation.name} to #{email} ")

                  ReminderMailer.deliver_reminder(reminder, "#{APPLICATION_URL}/invitations/show/#{invitation.id}")  rescue nil
                  if reminder.member.receives_sms_reminders?
                    begin
                      TextMessageNotifier.deliver_meeting_reminder(invitation.upcoming_meeting, reminder)
                    rescue => e
                      logger.error("Failed to send SMS reminder for reminder: #{reminder.id}, member #{reminder.member.user_name}, and meeting: #{invitation.upcoming_meeting.id rescue 'nil'}.")
                    end
                  end
                  
                  number_sent += 1
                  if(invitation.recurring?)  
											 next_meeting = invitation.next_meeting(invitation.next_meeting + 1.hour ) 
											 send_before = next_meeting - reminder.advance    
                                                                                         
         # Problem.....   send_before is < now  and is < invitation.next_meeting. That is wrong and casuing dups...
         send_before = ( Time.now + 1.day ) if( send_before < Time.now || send_before < invitation.next_meeting)
											 reminder.send_before = send_before      
											 reminder.dont_update_send_before = true
											 reminder.save!   
	                else
                  	reminder.update_attribute(:sent, true)
                  end
               else
                  logger.info("Testing:  Could have sent a reminder for #{reminder.invitation.id} #{reminder.invitation.name} to #{email}")
               end
            rescue
               logger.error "ERROR: Couldn't send #{reminder.id} to #{email}: #{$!}  "
            end
         end
      end
      logger.info("Sent #{number_sent} reminders.")
   end 



end
