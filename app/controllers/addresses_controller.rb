class AddressesController < ApplicationController

  before_filter :login_required
  
  def address_autocomplete
      @field = params[:address].keys.first
      value = params[:address][@field]
      @addresses = @viewer.addresses.find(:all, :conditions => [" addresses.#{@field} LIKE ? ", "%#{value}%"]).uniq
      render :layout => false
  end
end
