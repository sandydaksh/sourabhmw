class Admin::ConfirmationsController < ApplicationController   

  layout 'admin'
  before_filter :admin_required

  def index
    @confirmations = Confirmation.paginate(:order => 'updated_at desc', :page => (params[:page] || 1), :per_page => 50)
  end


end
