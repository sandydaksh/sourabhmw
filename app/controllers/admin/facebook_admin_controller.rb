class Admin::FacebookAdminController < ApplicationController

   layout 'admin'
   before_filter :admin_required
   require ( RAILS_ROOT + '/lib/gems/googlecharts-0.1.0/lib/gchart.rb' )
   def index
      @facebook_users = SocialNetworkUser.find :all , :include => [:member => [:invitations, :confirmations]]
      @removed_users = @facebook_users.select(&:remove_date)
      @linked_users = @facebook_users.select(&:merged_account?)
      @signed_up_via_facebook =  @linked_users.select{|u| u.created_at < u.member.created_at }
      @setup_profile = @facebook_users.reject{|u| u.setup_profile? }
      @posted_invite = @facebook_users.select{|fb_user| fb_user.member && fb_user.member.invitations.size > 0 }
      @has_confirmations = @facebook_users.select{|fb_user| fb_user.member && fb_user.member.confirmations && fb_user.member.confirmations.size > 0 }

      @activity = []
      @adding_activity = []
      @removed = []

      @facebook_users.each do |fb_user|
         next unless( time = fb_user.last_access   )
         time_diff = Time.now - time
         days_ago = (time_diff / 1.day   ).to_i
         @activity[days_ago] ||= 0
         @activity[days_ago] += 1

         time = fb_user.created_at
         time_diff = Time.now - time
         days_ago = (time_diff / 1.day   ).to_i
         @adding_activity[days_ago] ||= 0
         @adding_activity[days_ago] += 1

         if(time = fb_user.remove_date)
            time_diff = Time.now - time
            days_ago = (time_diff / 1.day   ).to_i
            @removed[days_ago] ||= 0
            @removed[days_ago] += 1
         end


      end

      @activity = @activity.collect{|value|
         value = 0 if value.nil?
         value
      }[0..45].reverse

      @adding_activity = @adding_activity.collect{|value|
         value = 0 if value.nil?
         value
      }[0..45].reverse

      @removed = @removed.collect{|value|
         value = 0 if value.nil?
         value
      }[0..45].reverse

   end

   def show_users
      index()
      @users = instance_variable_get("@" + params[:id])
      @title = params[:id]
   end

end
