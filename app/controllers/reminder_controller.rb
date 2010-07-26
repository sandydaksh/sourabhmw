class ReminderController < ApplicationController

  before_filter :login_required
  before_filter :get_invitation_and_user

  def set
    @reminder = Reminder.find_by_invitation_id_and_member_id(@invitation.id, @member.id)
    if (params[:reminder] and params[:reminder][:advance])
      @advance = params[:reminder][:advance]
      @invite_show_page = true
    else
      @advance = @member.default_reminder_advance
    end

    if @reminder.nil?
      @reminder = Reminder.create(:invitation_id => @invitation.id, :member_id => @member.id, :advance => @advance)
    end
  end

  def unset
    @reminder = Reminder.find_by_invitation_id_and_member_id(@invitation.id, @member.id)

    @invite_show_page = (params[:reminder] and params[:reminder][:advance])

    unless @reminder.nil?
      @reminder.destroy
    end
  end

  def update
    @reminder = Reminder.find_by_invitation_id_and_member_id(@invitation.id, @member.id)
    if (params[:reminder] and params[:reminder][:advance])
      @advance = params[:reminder][:advance]
      @reminder.update_attribute(:advance, @advance)
      @reminder.update_attribute(:sent, false)  # reset it so it will be sent again, in case it has already been set
    end

  end

  protected
  def get_invitation_and_user
    @invitation = Invitation.find(params[:id])
    @member = current_member
  end

end
