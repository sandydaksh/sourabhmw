class FacebookChatterObserver < ActiveRecord::Observer
   observe Invitation, Confirmation
   def after_create(record)
      begin
         if( Invitation === record)
            if( record.inviter.social_network_user)
               record.inviter.social_network_user.notify_post_invite(record)
            end
         end
      rescue Exception => err
         logger.error("FB ERROR:  Failed to publish post invite story for #{record.inspect} #{err.message} #{err.backtrace.join("\n")}")
         raise err unless(RAILS_ENV == "production")
      end
   end

   def after_save(record)
      begin
         if( Confirmation === record  && record.status_changed? &&record.member.social_network_user)   
	    logger.debug("************ \n\n\n\n\n Trying")
            unless( record.sent_notifications)
               record.member.social_network_user.notify_confirmation(record)
               record.sent_notifications = true
            end
         end
      rescue Exception => err
         logger.error("FB ERROR:  Failed to publish post invite story for #{record.inspect} #{err.message} #{err.backtrace.join("\n")}")
         throw err if(RAILS_ENV == "development")
      end
   end

   def logger
      RAILS_DEFAULT_LOGGER
   end

end
