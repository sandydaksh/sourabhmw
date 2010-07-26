class Admin::AirportsController < ApplicationController
  before_filter :admin_required
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @airports = Airport.paginate(:per_page => 10)
  end

  def show
    @airport = Airport.find(params[:id])
  end

  def new
    @airport = Airport.new
  end

  def create
    @airport = Airport.new(params[:airport])
    if @airport.save
      flash[:notice] = 'Airport was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @airport = Airport.find(params[:id])
  end

  def update
    @airport = Airport.find(params[:id])
    if @airport.update_attributes(params[:airport])
      flash[:notice] = 'Airport was successfully updated.'
      redirect_to :action => 'show', :id => @airport
    else
      render :action => 'edit'
    end
  end

  def destroy
    Airport.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
