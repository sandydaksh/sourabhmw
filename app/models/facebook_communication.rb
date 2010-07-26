class FacebookCommunication < ActiveRecord::Base
   serialize :data
   serialize :recipients
   def push
      raise "MethodNotOveridden"
   end
   def self.new_for_user(facebook_user)
      communication = self.new
      communication.session_key = facebook_user.session_key
      communication.uid = facebook_user.uid
      return communication
   end


   def facebook_session
      session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
      session.secure_with!(self.session_key,self.uid,0)
      session
   end

   def fb_user
      fb_user = Facebooker::User.new({:uid => self.uid, :session => self.facebook_session})
   end

   def recipients=(recipients)
      if( String === recipients )
         super(recipients.split(","))
      elsif( Array === recipients )
         if( recipients.first.respond_to?(:uid) )
            super(recipients.map(&:uid))
         else
            super(recipients)
         end
      elsif( recipients.respond_to?(:uid))
         super([recipients.uid])
      elsif( recipients.to_i > 0 )
         super([ recipients.to_i ])
      else
         "NotValidRecipientList"
      end
   end

   STATE_NEW = "new"
   STATE_WORKING = "working"
   STATE_COMPLETE = "complete"
   STATE_FAILED = "failed"
   MAX_FAILURES = 10

   def self.run_next(state = STATE_NEW, send_attempts = 0)
      next_to_run = grab_one_to_run(state, send_attempts)
      return false unless next_to_run
      next_to_run.state = STATE_FAILED
      begin
         next_to_run.push
         next_to_run.state = STATE_COMPLETE
         return next_to_run
      ensure
         next_to_run.save!
      end
   end

   def self.run_next_failed(number_of_failures)
      self.run_next(STATE_FAILED, number_of_failures)
   end

   def self.total_failures
      self.find(:all, :conditions => ["state = ? and send_attempts >= ?", STATE_FAILED, MAX_FAILURES])
   end

   def self.grab_one_to_run(state = STATE_NEW, send_attempts = 0)
      # grab one from the queue
      self.transaction do
         next_to_run = self.find(:first, :conditions => ["state = ? and send_after < ? and send_attempts = ?", state, Time.now, send_attempts], :order => "created_at", :lock => true)
         return false unless next_to_run
         next_to_run.state = STATE_WORKING
         next_to_run.send_attempts += 1
         next_to_run.last_send_attempt = Time.now
         next_to_run.save!
         return next_to_run

      end
   end
end
