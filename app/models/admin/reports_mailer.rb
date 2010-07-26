class Admin::ReportsMailer < ActionMailer::Base
  helper :invitations
  helper :application
  helper :invitation_notify

  def nightly(unverified_members, verified_members, posted_invites, unfinished_invites) 
    @time = Time.now  
    @recipients = "nightlyreports@travelerstable.com"
    @from       = 'MeetingWave Report Bot <reports@meetingwave.com>'
    @subject    = "MeetingWave.com Nightly Report #{@time.strftime('%m/%d/%y')} "
    @sent_on    = Time.now
    headers['Content-Type'] = "text/plain; charset=#{MemberSystem::CONFIG[:mail_charset]}; format=flowed"
    @body['time'] = @time
    @body['unverified_members'] = unverified_members
    @body["verified_members"]   = verified_members
    @body["posted_invites"]     = posted_invites
    @body["unfinished_invites"] = unfinished_invites
  end

  def weekly(unverified_members, verified_members, unverified_members_since_launch, all_members_since_launch, posted_invites, unfinished_invites, posted_invites_since_launch) 
    @time = Time.now  
    @recipients = "weeklyreports@travelerstable.com"
    @from       = 'MeetingWave Report Bot <reports@meetingwave.com>'
    @subject    = "MeetingWave.com Weekly Report #{@time.strftime('%m/%d/%y')} "
    @sent_on    = Time.now
    headers['Content-Type'] = "text/plain; charset=#{MemberSystem::CONFIG[:mail_charset]}; format=flowed"
    @body['time'] = @time
    @body['unverified_members'] = unverified_members
    @body["verified_members"]   = verified_members
    @body["posted_invites"]     = posted_invites
    @body["unfinished_invites"] = unfinished_invites
    @body["unverified_members_since_launch"] = unverified_members_since_launch
    @body["all_members_since_launch"] = all_members_since_launch
    @body["posted_invites_since_launch"] = posted_invites_since_launch
  end



end
