class PeriodicTasks


  def self.do_nightly_report
    
    @unverified_members = Member.find(:all, :conditions => [ 'verified = 0 AND created_at > DATE_ADD(CURDATE(), INTERVAL -1 DAY)'])
    @verified_members = Member.find(:all, :conditions => [ 'verified = 1 AND created_at > DATE_ADD(CURDATE(), INTERVAL -1 DAY)'])

    @posted_invites = Invitation.find(:all, :conditions => ['draft_status = "posted" AND created_at > DATE_ADD(CURDATE(), INTERVAL -1 DAY)'])
    @unfinished_invites = Invitation.find(:all, :conditions => ['draft_status = "draft" AND created_at > DATE_ADD(CURDATE(), INTERVAL -1 DAY)'])
    Admin::ReportsMailer.deliver_nightly(@unverified_members, @verified_members, @posted_invites, @unfinished_invites)
    
  end
  
  def self.do_weekly_report
    @unverified_members = Member.find(:all, :conditions => [ 'verified = 0 AND created_at > DATE_ADD(CURDATE(), INTERVAL -7 DAY)'])
    @verified_members = Member.find(:all, :conditions => [ 'verified = 1 AND created_at > DATE_ADD(CURDATE(), INTERVAL -7 DAY)'])
    @unverified_members_since_launch = Member.find(:all, :conditions => [ "verified = 0 AND created_at > '2007-05-30 12:00:00'"], :order => "created_at DESC")
    
    @all_members_since_launch = Member.find(:all, :conditions => [ "created_at > '2007-05-30 12:00:00'"], :order => "created_at DESC")

    @posted_invites = Invitation.find(:all, :conditions => ['draft_status = "posted" AND created_at > DATE_ADD(CURDATE(), INTERVAL -7 DAY)'])
    @unfinished_invites = Invitation.find(:all, :conditions => ['draft_status = "draft" AND created_at > DATE_ADD(CURDATE(), INTERVAL -7 DAY)'])
    @posted_invites_since_launch = Invitation.find(:all, :conditions => ["draft_status = 'posted' AND created_at > '2007-05-30 12:00:00'"])
    
    Admin::ReportsMailer.deliver_weekly(@unverified_members, @verified_members, @unverified_members_since_launch, @all_members_since_launch, @posted_invites, @unfinished_invites, @posted_invites_since_launch)
    
  end




end