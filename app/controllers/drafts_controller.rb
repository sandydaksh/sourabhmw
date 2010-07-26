class DraftsController < ApplicationController
  before_filter :login_required
  helper :invitations

  def list
    @drafts = @viewer.drafts
  end

  def delete
    @draft = @viewer.drafts.find(params[:id])
    @draft.destroy
  end


end
