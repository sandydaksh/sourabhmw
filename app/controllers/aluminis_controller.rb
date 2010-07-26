class AluminisController < ApplicationController
  layout 'aluminis'
  before_filter :university_admin_required
  # GET /aluminis
  # GET /aluminis.xml
  def index
    @aluminis = Alumini.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @aluminis }
    end
  end

  # GET /aluminis/1
  # GET /aluminis/1.xml
  def show
    @alumini = Alumini.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @alumini }
    end
  end

  # GET /aluminis/new
  # GET /aluminis/new.xml
  def new
    @universities = University.all
    @university = University.find(:first,:conditions => ["name = ?",private_mw])
    @alumini = Alumini.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @alumini }
    end
  end

  # GET /aluminis/1/edit
  def edit
    @university = University.find(:first,:conditions => ["name = ?",private_mw])
    @universities = University.all
    @alumini = Alumini.find(params[:id])
  end

  # POST /aluminis
  # POST /aluminis.xml
  def create
    @universities = University.all
    @university = University.find(:first,:conditions => ["name = ?",private_mw])
    @alumini = Alumini.new(params[:alumini])

    respond_to do |format|
      if @alumini.save
        flash[:notice] = 'Alumini was successfully created.'
        format.html { redirect_to(aluminis_url) }
        format.xml  { render :xml => @alumini, :status => :created, :location => @alumini }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @alumini.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /aluminis/1
  # PUT /aluminis/1.xml
  def update
    @alumini = Alumini.find(params[:id])
    @universities = University.all
    @university = University.find(:first,:conditions => ["name = ?",private_mw])
    respond_to do |format|
      if @alumini.update_attributes(params[:alumini])
        flash[:notice] = 'Alumini was successfully updated.'
        format.html { redirect_to(aluminis_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @alumini.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /aluminis/1
  # DELETE /aluminis/1.xml
  def destroy
    @alumini = Alumini.find(params[:id])
    @alumini.destroy

    respond_to do |format|
      format.html { redirect_to(aluminis_url) }
      format.xml  { head :ok }
    end
  end
end
