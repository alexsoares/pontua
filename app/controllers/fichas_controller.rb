class FichasController < ApplicationController
  before_filter :load_professors

layout 'ficha'
  # GET /fichas
  # GET /fichas.xml
  def index
    @fichas = @professor.fichas.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fichas }
    end
  end

  # GET /fichas/1
  # GET /fichas/1.xml
  def show
    @ficha = @professor.fichas.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ficha }
    end
  end


  # DELETE /fichas/1
  # DELETE /fichas/1.xml
  def destroy
    @ficha = @professor.fichas.find(params[:id])
    @ficha.destroy

    respond_to do |format|
      format.html { redirect_to fichas_url(@professor) }
      format.xml  { head :ok }
    end
  end

  protected

  def load_professors
    @professor = Professor.find(params[:professor_id], :include => :fichas)
  end
end
