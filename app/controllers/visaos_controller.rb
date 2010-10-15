class VisaosController < ApplicationController
  before_filter :login_required
  before_filter :load_professors
  layout 'exibicao'
  # GET /visaos
  # GET /visaos.xml
  def index
    @search = Professor.search(params[:search])
    if !(params[:search].blank?)
        if params[:search][:funcao_equals] == 'TODOS'
          @search = Professor.search(params[:search])
          @professor_rel_geral = Professor.all(:joins => :unidade, :conditions => ["unidades.tipo in (1,2,3)"], :order => 'pontuacao_final DESC')
        else
          @search = Professor.search(params[:search])
          @professor_rel_geral = @search.all(:joins => :unidade, :conditions => ["unidades.tipo in (1,2,3)"], :order => 'pontuacao_final DESC')
        end
    end
  end

protected

  def load_professors
    @professors = Professor.find(:all,:joins => :unidade, :conditions => ["unidades.tipo in (1,2,3)"], :order => "matricula")
  end

end
