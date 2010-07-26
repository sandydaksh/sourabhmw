class Admin::MilitaryBranchesController < ApplicationController
  before_filter :admin_required
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
     @military_branches = MilitaryBranch.paginate(:per_page => 10)
  end

  def show
    @military_branch = MilitaryBranch.find(params[:id])
  end

  def new
    @military_branch = MilitaryBranch.new
  end

  def create
    @military_branch = MilitaryBranch.new(params[:military_branch])
    if @military_branch.save
      flash[:notice] = 'MilitaryBranch was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @military_branch = MilitaryBranch.find(params[:id])
  end

  def update
    @military_branch = MilitaryBranch.find(params[:id])
    if @military_branch.update_attributes(params[:military_branch])
      flash[:notice] = 'MilitaryBranch was successfully updated.'
      redirect_to :action => 'show', :id => @military_branch
    else
      render :action => 'edit'
    end
  end

  def destroy
    MilitaryBranch.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
