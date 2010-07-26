class Admin::SportsTeamsController < ApplicationController
  before_filter :admin_required
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
     @sports_teams = SportsTeam.paginate(:per_page => 10)
  end

  def show
    @sports_team = SportsTeam.find(params[:id])
  end

  def new
    @sports_team = SportsTeam.new
  end

  def create
    @sports_team = SportsTeam.new(params[:sports_team])
    if @sports_team.save
      flash[:notice] = 'SportsTeam was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @sports_team = SportsTeam.find(params[:id])
  end

  def update
    @sports_team = SportsTeam.find(params[:id])
    if @sports_team.update_attributes(params[:sports_team])
      flash[:notice] = 'SportsTeam was successfully updated.'
      redirect_to :action => 'show', :id => @sports_team
    else
      render :action => 'edit'
    end
  end

  def destroy
    SportsTeam.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
