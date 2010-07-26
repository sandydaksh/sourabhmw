class Admin::OccupationsController < ApplicationController
  before_filter :admin_required
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @occupations = Occupation.paginate(:per_page => 10)
  end

  def show
    @occupation = Occupation.find(params[:id])
  end

  def new
    @occupation = Occupation.new
  end

  def create
    @occupation = Occupation.new(params[:occupation])
    if @occupation.save
      flash[:notice] = 'Occupation was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @occupation = Occupation.find(params[:id])
  end

  def update
    @occupation = Occupation.find(params[:id])
    if @occupation.update_attributes(params[:occupation])
      flash[:notice] = 'Occupation was successfully updated.'
      redirect_to :action => 'show', :id => @occupation
    else
      render :action => 'edit'
    end
  end

  def destroy
    Occupation.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
