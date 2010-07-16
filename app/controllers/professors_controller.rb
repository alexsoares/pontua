class ProfessorsController < ApplicationController
before_filter :load_titulos
before_filter :load_unidades
before_filter :sede_unidade
before_filter :load_trabalhados
before_filter :load_titulacao
before_filter :load_titulo_professor
before_filter :load_professorsnome
before_filter :load_regiaos
before_filter :load_calculos
before_filter :load_funcao
before_filter :login_required
require_role ['direcao',"supervisao","admin"], :for => :update # don't allow contractors to destroy
require_role ["supervisao","admin"], :for => :destroy # don't allow contractors to destroy
  # GET /professors
  # GET /professors.xml

  def login
    if !logged_in? then
      redirect_to(new_session_path)
    else
      render :action =>[ :url => 'destroy',:controller => 'sessions']
    end
  end


  def index
    if (params[:search].nil? || params[:search].empty?)
      @professors = Professor.find(:all, :order =>  'nome ASC')
      #@professors = Professor.paginate(:page => params[:page], :per_page => 30)
    else
      #@professors = Professor.find(:all, :conditions => ["matricula = ?",params[:search]])
      #@professors = Professor.paginate(:page => params[:page], :per_page => 30,:conditions => ["matricula = ?",params[:search]])
       @professors = Professor.find(:all, :conditions => ["nome like ?", "%" + params[:search].to_s + "%"])
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @professors }
    end
  end


  # GET /professors/1
  # GET /professors/1.xml
  def show
    @professor = Professor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @professor }
    end
  end

  # GET /professors/new
  # GET /professors/new.xml
  def new
    @professor = Professor.new
    $contador=0
    $Total_de_titulos=0

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @professor }
    end
  end

  # GET /professors/1/edit
  def edit
    @professor = Professor.find(params[:id])
  end

  # POST /professors
  # POST /professors.xml
  def create
    @professor = Professor.new(params[:professor])
    @professor.log_user = current_user.id
    respond_to do |format|
      if @professor.save
        flash[:notice] = 'PROFESSOR CADASTRADO COM SUCESSO.'
        format.html { redirect_to(@professor) }
        format.xml  { render :xml => @professor, :status => :created, :location => @professor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @professor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /professors/1
  # PUT /professors/1.xml
  def update
    @professor = Professor.find(params[:id])
    @log = Log.new
    @log.log(current_user, @professor.id, "Atualizado dados do professor: #{@professor.id}")

    respond_to do |format|
      if @professor.update_attributes(params[:professor])
          flash[:notice] = 'PROFESSOR ATUALIZADO COM SUCESSO.'
          format.html { redirect_to(@professor) }
          format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @professor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /professors/1
  # DELETE /professors/1.xml
  def destroy
    @professor = Professor.find(params[:id])
    $prof_id = params[:id]
    @titulo_professor = TituloProfessor.find(:all, :conditions => ['professor_id = ' + $prof_id])
    @acum_professor = AcumTrab.find(:all, :conditions => ['professor_id = ' + $prof_id])
    @trabalhado_professor = Trabalhado.find(:all, :conditions => ['professor_id = ' + $prof_id])
    for titu_prof in @titulo_professor
      titu_prof.destroy
    end
    for trab_prof in @trabalhado_professor
      trab_prof.destroy
    end
    for acum_prof in @acum_professor
      acum_prof.destroy
    end

    @log = Log.new
    @log.log(current_user, @professor.id, "Excluído o professor:#{@professor.id} - #{@professor.nome} ")

    @professor.destroy

    respond_to do |format|
      format.html { redirect_to(professors_url) }
      format.xml  { head :ok }
    end
  end


  def soma_dias
    @soma_dias = Trabalhado.find_by_sql('Select sum(total_dias_trab) from trabalhados where professor_id = '+$professor)
    return @soma_dias
  end

  def nome_professor
    $professor = params[:professor_professor_id]
    @professors = Professor.find(:all, :conditions => ['id=' + $professor ])
    #render :partial => 'lista_professor'
    render :update do |page|
      page.replace_html 'titula', :text => ''
      page.replace_html 'dados_professor', :partial => 'lista_professor'
    end

  end


  def desc
    @titulo_desc = Titulacao.find(:all, :conditions => ["id="+ params[:professor_titulacao_id]])
    if not @titulo_desc.empty? then
       $contador=0
       render :update do |page|
         page.insert_html :bottom , 'desc_titulo', :text =>  "Código: " + (Titulacao.find_by_id(params[:professor_titulacao_id]).id).to_s     + " - Descrição do Título: " + (Titulacao.find_by_id(params[:professor_titulacao_id]).descricao).to_s + '<br/>'
         page.replace_html 'contador', :text => ''
        end
    end
  end

  def rel_prof

    if current_user.regiao_id == 52 or current_user.regiao_id == 53 then
    #@professors = Professor.find_by_sql("Select * from  professors order by nome")
    @professors = Professor.all(:include => :unidade, :order => 'professors.nome')
    else
    #@professors = Professor.find_by_sql("Select * from  professors p where p.sede_id = " + current_user.regiao_id.to_s + " or p.sede_id = 54 order by nome")
    @professors = Professor.find(:all, :conditions => 'sede_id = ' + current_user.regiao_id.to_s + 'or sede_id = 54',:include => :unidade ,:order => 'nome')
    end

    $consulta=0
    $tipo_con = 0
    render :update do |page|
      page.replace_html 'tempo_serv', :text =>''
      page.replace_html 'prof_pontua', :partial => 'relatorio_professors'
    end

  end

  def relato_prof
      render :update do |page|
      page.replace_html 'conteudo', :text =>''
      page.replace_html 'titula', :text=>''
      page.replace_html 'conteudo', :partial => 'professor_relatorio_pontuacao'
      end
  end


  def dados_professor
     $exibe_dias_trab_ano = 0
     $exibe_dias_efet_ano = 0
     $exibe_dias_rede_ano = 0
     $exibe_dias_unid_ano = 0

     $exibe_dias_ant_trab_ano = 0
     $exibe_dias_ant_efet_ano = 0
     $exibe_dias_ant_rede_ano = 0
     $exibe_dias_ant_unid_ano = 0

     $exibe_dias_trab_ano = 0
     $exibe_dias_efet_ano = 0
     $exibe_dias_rede_ano = 0
     $exibe_dias_unid_ano = 0

     $exibe_ano_anterior_dias_trab = 0
     $exibe_ano_anterior_dias_efet  = 0
     $exibe_ano_anterior_dias_rede  = 0
     $exibe_ano_anterior_dias_unid  = 0

     $exibe_ano_atual_dias_trab = 0
     $exibe_ano_atual_dias_efet  = 0
     $exibe_ano_atual_dias_rede  = 0
     $exibe_ano_atual_dias_unid  = 0

     $exibe_tot_geral_trab = 0
     $exibe_tot_geral_efet = 0
     $exibe_tot_geral_rede = 0
     $exibe_tot_geral_unid = 0

     $dias_trab_ano = 0
     $tot_dias_trab = 0
     $st_dt = 0
     $st_de = 0
     $st_dr = 0
     $st_du = 0
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0

     $exibe_pont_trab = 0
     $exibe_pont_efet = 0
     $exibe_pont_rede = 0
     $exibe_pont_unid = 0

     $exibe_tot_trab = 0
     $exibe_tot_efet = 0
     $exibe_tot_rede = 0
     $exibe_tot_unid = 0

     $total_trab_g = 0
     $total_efet_g = 0
     $total_rede_g = 0
     $total_unid_g = 0

     $ano_anterior_dias_trab = 0
     $ano_anterior_dias_efet = 0
     $ano_anterior_dias_rede = 0
     $ano_anterior_dias_unid = 0

     $ano_atual_dias_trab = 0
     $ano_atual_dias_efet = 0
     $ano_atual_dias_rede = 0
     $ano_atual_dias_unid = 0

    $acum_dias_trab_ano = 0
    $acum_dias_efet_ano = 0
    $acum_dias_rede_ano = 0
    $acum_dias_unid_ano = 0

    $pont_trab = 0
    $pont_efet = 0
    $pont_rede = 0
    $pont_unid = 0

     $dias_trab_ano = 0
     $tot_dias_trab = 0
     $st_dt = 0
     $st_de = 0
     $st_dr = 0
     $st_du = 0
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0
     $professor_mat = ''
     $professor_mat = params[:professor_professor_id]
     if !($professor_mat).nil? or !($professor_mat).empty? or !($professor_mat == '')

      if !(Professor.find_by_matricula($professor_mat)).nil? then
      $professor = Professor.find_by_matricula($professor_mat).id.to_s
    # =======================================
#|| Inicio Calculos de Tempo de Serviço  ||
# =======================================

    @acum = AcumTrab.find(:all, :conditions => ['professor_id = ' + $professor])
    for tot_dias in @acum
       $anterior_dias_trab = tot_dias.tot_acum_trab.to_i
       $anterior_dias_efet = tot_dias.tot_acum_efet.to_i
       $anterior_dias_rede = tot_dias.tot_acum_rede.to_i
       $anterior_dias_unid = tot_dias.tot_acum_unid.to_i
       $acum_dias_trab_ano = tot_dias.tot_acum_trab.to_i
       $acum_dias_efet_ano = tot_dias.tot_acum_efet.to_i
       $acum_dias_rede_ano = tot_dias.tot_acum_rede.to_i
       $acum_dias_unid_ano = tot_dias.tot_acum_unid.to_i
    end
     @dias_trab_anterior = Trabalhado.find(:all, :conditions => ['ano = ' + $data2.to_s + ' and professor_id= ' + $professor + ' and flag = 0 and ano_letivo = ' + $data.to_s])
      for ano_anterior in @dias_trab_anterior
       ano_anterior.dias_trab
          $ano_anterior_dias_trab = ano_anterior.dias_trab
          $ano_anterior_dias_efet = ano_anterior.dias_efetivos
          $ano_anterior_dias_rede = ano_anterior.dias_rede
          $ano_anterior_dias_unid = ano_anterior.dias_unidade
       end
      @dias_trab_atual = Trabalhado.find(:all, :conditions => ['ano = ' + $data.to_s + ' and professor_id= ' + $professor + ' and flag = 0 and ano_letivo = ' + $data.to_s])
         for ano_atual in @dias_trab_atual
          ano_atual.dias_trab
          $ano_atual_dias_trab = ano_atual.dias_trab
          $ano_atual_dias_efet = ano_atual.dias_efetivos
          $ano_atual_dias_rede = ano_atual.dias_rede
          $ano_atual_dias_unid = ano_atual.dias_unidade
       end

        $total_trab_g = $acum_dias_trab_ano + $ano_anterior_dias_trab + $ano_atual_dias_trab
        $total_efet_g = $acum_dias_efet_ano + $ano_anterior_dias_efet + $ano_atual_dias_efet
        $total_rede_g = $acum_dias_rede_ano + $ano_anterior_dias_rede + $ano_atual_dias_rede
        $total_unid_g = $acum_dias_unid_ano + $ano_anterior_dias_unid + $ano_atual_dias_unid
        @acum_pont = AcumTrab.find(:all, :conditions => ['professor_id= ' + $professor])
       for pontuacao in @acum_pont
        $pont_trab = pontuacao.pont_base_trab
        $pont_efet = pontuacao.pont_base_efet
        $pont_rede = pontuacao.pont_base_rede
        $pont_unid = pontuacao.pont_base_unid
       end
        $total_trab = $pont_trab * $total_trab_g
        $total_efet = $pont_efet * $total_efet_g
        $total_rede = $pont_rede * $total_rede_g
        $total_unid = $pont_unid * $total_unid_g
# =======================================
#|| Fim Calculos de Tempo de Serviço     ||
# =======================================



    @professors = Professor.find(:all, :conditions => ['id=' + $professor ])
    #@trabalho1 = Trabalhado.find(:all, :conditions => ['professor_id=' +$professor,'ano_letivo = ' + $data.to_s])
    @trabalho1 = Trabalhado.find_by_sql("SELECT * FROM trabalhados WHERE professor_id = " + $professor + " and ano_letivo = " + $data.to_s)
    #@trabalho = Trabalhado.find(:all, :conditions => ['professor_id=' +$professor,'ano_letivo = ' + $data.to_s])
    @trabalho = Trabalhado.find_by_sql("SELECT * FROM trabalhados WHERE professor_id = " + $professor + " and ano_letivo = " + $data.to_s)
    #@t = Trabalhado.find(:all, :conditions => ['professor_id=' +$professor,'ano_letivo = ' + $data.to_s])
    @t = Trabalhado.find_by_sql("SELECT * FROM trabalhados WHERE professor_id = " + $professor + " and ano_letivo = " + $data.to_s)
    @nome_professor = Professor.find_by_id($professor)

    @tp = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $professor + " and t.tipo = 'PERMANENTE'")
    @tp1 = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $professor + " and t.tipo = 'ANUAL'")
    @tp5 = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $professor + " and t.tipo = '5 ANOS'")
    $zerar = 1
    render :update do |page|
      page.replace_html 'titula', :text => ''
      page.replace_html 'dados_professor', :partial => 'exibicao_pontuatempservico'
    end
  else
    render :update do |page|
      page.replace_html 'dados_professor', :text => 'Matricula Não cadastrada'
    end
  end
 else
    render :update do |page|
      page.replace_html 'dados_professor', :text => ''
    end

 end
end

  def efetiva
    @reinicia_tbltrabalhados = Trabalhado.find_all_by_professor_id($prof_zerar)
    @reinicia_tblacum_trabs = AcumTrab.find_by_professor_id($prof_zerar)
    @reinicia_titulo_professors = TituloProfessor.find_all_by_professor_id($prof_zerar)
    if !@reinicia_tblacum_trabs.nil? then
      @reinicia_tblacum_trabs = AcumTrab.find_by_professor_id($prof_zerar).id
      @reinicia_tblacum_trabs = AcumTrab.find(@reinicia_tblacum_trabs)
          @atualiza_log = Log.new
          @atualiza_log.user_id = current_user.id
          @atualiza_log.obs = "Reiniciado valores acumulados dos funcionários"
          @atualiza_log.data = (Time.now().strftime("%d/%m/%y %H:%M")).to_s
          @atualiza_log.professor_id = @reinicia_tblacum_trabs.professor_id
          @atualiza_log.acumtrab_id = @reinicia_tblacum_trabs.id
          @atualiza_log.save
      @reinicia_tblacum_trabs.destroy
    end
    if !@reinicia_titulo_professors.nil? then
      for titulos in @reinicia_titulo_professors
              @atualiza_log = Log.new
              @atualiza_log.user_id = current_user.id
              @atualiza_log.obs = "Exclusão de titulo através de reinicialização geral"
              @atualiza_log.data = (Time.now().strftime("%d/%m/%y %H:%M")).to_s
              @atualiza_log.professor_id = titulos.professor_id
              @atualiza_log.titulacao_id = titulos.id
              @atualiza_log.save

        @reinicia_titulo_professors = (titulos).id
        @reinicia_titulo_professors = TituloProfessor.find(@reinicia_titulo_professors)
        titulos.destroy
      end
    end
    if !@reinicia_tbltrabalhados.nil? or !@reinicia_tbltrabalhados.empty?  then
      for trabalhos in @reinicia_tbltrabalhados
        @reinicia_tbltrabalhados = (trabalhos).id
        @reinicia_tbltrabalhados = Trabalhado.find(@reinicia_tbltrabalhados)
              @atualiza_log = Log.new
              @atualiza_log.user_id = current_user.id
              @atualiza_log.obs = "Exclusão do tempo trabalhado através de reinicialização geral"
              @atualiza_log.data = (Time.now().strftime("%d/%m/%y %H:%M")).to_s
              @atualiza_log.professor_id = trabalhos.professor_id
              @atualiza_log.titulacao_id = trabalhos.id
              @atualiza_log.save


        trabalhos.destroy
      end
    end

    @reinicia_tblprof = Professor.find($prof_zerar)
    @reinicia_tblprof.total_titulacao = 0
    @reinicia_tblprof.pontuacao_final = @reinicia_tblprof.pontuacao_final - @reinicia_tblprof.total_trabalhado
    @reinicia_tblprof.total_trabalhado = 0
    @reinicia_tblprof.log_user = current_user.id
    @reinicia_tblprof.save

    @atualiza_log = Log.new
    @atualiza_log.user_id = current_user.id
    @atualiza_log.obs = "Reiniciado valores dos funcionários"
    @atualiza_log.data = (Time.now().strftime("%d/%m/%y %H:%M")).to_s
    @atualiza_log.professor_id = @reinicia_tblprof.id
    @atualiza_log.save

    if $reinicializacao == 1 then
      $reinicializacao = 0
      flash[:notice] = 'DADOS DO PROFESSOR REINICIADO.'
      redirect_to professors_path
    end
    $prof_zerar = 0
  end

  def sel_prof_zerar
    $prof_zerar = params[:zero_professor_id]
    render :update do |page|
      page.replace_html 'nome_prof', :text => 'Professor: ' + Professor.find($prof_zerar).nome
    end    
  end

  def efetiva_tit

   @reinicia_titulo_professors = TituloProfessor.find_all_by_professor_id($prof_zerar)
   if !@reinicia_titulo_professors.nil? then
      for titulos in @reinicia_titulo_professors
        @reinicia_titulo_professors = (titulos).id
        @reinicia_titulo_professors = TituloProfessor.find(@reinicia_titulo_professors)
              @atualiza_log = Log.new
              @atualiza_log.user_id = current_user.id
              @atualiza_log.obs = "Exclusão de titulo através de reinicialização de titulos"
              @atualiza_log.data = (Time.now().strftime("%d/%m/%y %H:%M")).to_s
              @atualiza_log.professor_id = titulos.professor_id
              @atualiza_log.titulacao_id = titulos.id
              @atualiza_log.save

        titulos.destroy
      end
    end
    @reinicia_tblprof = Professor.find($prof_zerar)
    @reinicia_tblprof.pontuacao_final = @reinicia_tblprof.pontuacao_final - @reinicia_tblprof.total_titulacao
    @reinicia_tblprof.total_titulacao = 0   
    @reinicia_tblprof.log_user = current_user.id
    @reinicia_tblprof.save
    if $reinicializacao == 1 then
      $reinicializacao = 0
      flash[:notice] = 'DADOS TITULAÇÂO DO PROFESSOR REINICIADO.'
      redirect_to professors_path
    end
	$prof_zerar = 0
  render :nothing => true
  end

  def reiniciar
    $prof_id = params[:professor_professor_id]
    render :partial => 'zerar'
  end

  def rel
     $dias_trab_ano = 0
     $tot_dias_trab = 0
     $st_dt = 0
     $st_de = 0
     $st_dr = 0
     $st_du = 0
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0

     $exibe_pont_trab = 0
     $exibe_pont_efet = 0
     $exibe_pont_rede = 0
     $exibe_pont_unid = 0

     $exibe_tot_trab = 0
     $exibe_tot_efet = 0
     $exibe_tot_rede = 0
     $exibe_tot_unid = 0

     $dias_trab_ano = 0
     $tot_dias_trab = 0
     $st_dt = 0
     $st_de = 0
     $st_dr = 0
     $st_du = 0
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0

     $anterior_dias_trab = 0
     $anterior_dias_trab = 0
     $anterior_dias_trab = 0
     $anterior_dias_trab = 0

     $ano_anterior_dias_trab = 0
     $ano_anterior_dias_efet = 0
     $ano_anterior_dias_rede = 0
     $ano_anterior_dias_unid = 0

     $ano_atual_dias_trab = 0
     $ano_atual_dias_efet = 0
     $ano_atual_dias_rede = 0
     $ano_atual_dias_unid = 0


     $acum_dias_trab_ano = 0
     $acum_dias_efet_ano = 0
     $acum_dias_rede_ano = 0
     $acum_dias_unid_ano = 0



# =======================================
#|| Inicio Calculos de Tempo de Serviço  ||
# =======================================

    @acum = AcumTrab.find(:all, :conditions => ['professor_id = ' + $professor])
    for tot_dias in @acum
       $anterior_dias_trab = tot_dias.tot_acum_trab.to_i
       $anterior_dias_efet = tot_dias.tot_acum_efet.to_i
       $anterior_dias_rede = tot_dias.tot_acum_rede.to_i
       $anterior_dias_unid = tot_dias.tot_acum_unid.to_i
       $acum_dias_trab_ano = tot_dias.tot_acum_trab.to_i
       $acum_dias_efet_ano = tot_dias.tot_acum_efet.to_i
       $acum_dias_rede_ano = tot_dias.tot_acum_rede.to_i
       $acum_dias_unid_ano = tot_dias.tot_acum_unid.to_i
    end
     @dias_trab_anterior = Trabalhado.find(:all, :conditions => ['ano = ' + $data2.to_s + ' and professor_id= ' + $professor + ' and flag = 0'])
      for ano_anterior in @dias_trab_anterior
       ano_anterior.dias_trab
          $ano_anterior_dias_trab = ano_anterior.dias_trab
          $ano_anterior_dias_efet = ano_anterior.dias_efetivos
          $ano_anterior_dias_rede = ano_anterior.dias_rede
          $ano_anterior_dias_unid = ano_anterior.dias_unidade
       end
      @dias_trab_atual = Trabalhado.find(:all, :conditions => ['ano = ' + $data.to_s + ' and professor_id= ' + $professor + ' and flag = 0'])
         for ano_atual in @dias_trab_atual
          ano_atual.dias_trab
          $ano_atual_dias_trab = ano_atual.dias_trab
          $ano_atual_dias_efet = ano_atual.dias_efetivos
          $ano_atual_dias_rede = ano_atual.dias_rede
          $ano_atual_dias_unid = ano_atual.dias_unidade
       end
        $total_trab_g = $acum_dias_trab_ano + $ano_anterior_dias_trab + $ano_atual_dias_trab
        $total_efet_g = $acum_dias_efet_ano + $ano_anterior_dias_efet + $ano_atual_dias_efet
        $total_rede_g = $acum_dias_rede_ano + $ano_anterior_dias_rede + $ano_atual_dias_rede
        $total_unid_g = $acum_dias_unid_ano + $ano_anterior_dias_unid + $ano_atual_dias_unid
        @acum_pont = AcumTrab.find(:all, :conditions => ['professor_id= ' + $professor])
       for pontuacao in @acum_pont
        $pont_trab = pontuacao.pont_base_trab
        $pont_efet = pontuacao.pont_base_efet
        $pont_rede = pontuacao.pont_base_rede
        $pont_unid = pontuacao.pont_base_unid
       end
        $total_trab = $pont_trab * $total_trab_g
        $total_efet = $pont_efet * $total_efet_g
        $total_rede = $pont_rede * $total_rede_g
        $total_unid = $pont_unid * $total_unid_g
# =======================================
#|| Fim Calculos de Tempo de Serviço     ||
# =======================================


    $data1 = Time.current.strftime("%Y")
    $data = $data1.to_i
    $data2 = $data -1
    @trabalho = Trabalhado.find(:all, :conditions => ['professor_id=' + $professor + ' and (ano = '+ $data2.to_s + ' or ano = ' + $data.to_s + ') and flag = 0'])
    @t = Trabalhado.find(:all, :conditions => ['professor_id=' + $professor])
    @nome_professor = Professor.find_by_id($professor)
    if @trabalho.nil? or @trabalho.empty? then
      $existe = 1
    else
      $existe = 0
    end
    render :partial => 'relatorio_tempo_servico'
  end

  def mesmo_nome
    $mat = params[:professor_matricula]
    @verifica = Professor.find_by_matricula($mat)
    if @verifica then
      render :update do |page|
        page.replace_html 'nome_aviso', :partial => 'showdados'
        page.replace_html 'Certeza', :text =>  'PROFESSOR JÁ CADASTRADO '
      end

    else
      render :update do |page|
        #page.replace_html 'nome_aviso', :text => ''
      end

    end
  end

 def consulta
    $v = 0

    render :update do |page|
      page.replace_html 'tempo', :text => ''
      page.replace_html 'conteudo', :partial => 'selecione_consulta'
    end

 end

def efetivar_zerar_titulos
    $prof_id = params[:t_professor_id]
    @tp = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $prof_id + " and t.tipo = 'PERMANENTE'")
    @tp1 = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $prof_id + " and t.tipo = 'ANUAL'")
    render :update do |page|
      page.replace_html 'zerar', :partial => 'lista_titulos_professor'
    end

end

def zerar_titulos
    render :update do |page|
      page.replace_html 'zerar', :partial => 'zerar_titulos'
    end
end

  def relatorio_indiv
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0
     $dias_trab_ano = 0
     $tot_dias_trab = 0
     $st_dt = 0
     $st_de = 0
     $st_dr = 0
     $st_du = 0
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0

     $exibe_pont_trab = 0
     $exibe_pont_efet = 0
     $exibe_pont_rede = 0
     $exibe_pont_unid = 0

     $exibe_tot_trab = 0
     $exibe_tot_efet = 0
     $exibe_tot_rede = 0
     $exibe_tot_unid = 0

     $dias_trab_ano = 0
     $tot_dias_trab = 0
     $st_dt = 0
     $st_de = 0
     $st_dr = 0
     $st_du = 0
     $soma_st_dt = 0
     $soma_st_de = 0
     $soma_st_dr = 0
     $soma_st_du = 0

     $anterior_dias_trab = 0
     $anterior_dias_trab = 0
     $anterior_dias_trab = 0
     $anterior_dias_trab = 0

     $ano_anterior_dias_trab = 0
     $ano_anterior_dias_efet = 0
     $ano_anterior_dias_rede = 0
     $ano_anterior_dias_unid = 0

     $ano_atual_dias_trab = 0
     $ano_atual_dias_efet = 0
     $ano_atual_dias_rede = 0
     $ano_atual_dias_unid = 0


     $acum_dias_trab_ano = 0
     $acum_dias_efet_ano = 0
     $acum_dias_rede_ano = 0
     $acum_dias_unid_ano = 0

    @trabalho = Trabalhado.find(:all, :conditions => ['professor_id=' +$professor])
    @t = Trabalhado.find(:all, :conditions => ['professor_id=' +$professor])
    @nome_professor = Professor.find_by_id($professor)
    @professors = Professor.find(:all, :conditions => ['id=' + $professor ])
    @tp = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $professor + " and t.tipo = 'PERMANENTE'")
    @tp1 = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $professor + " and t.tipo = 'ANUAL'")
    @tp5 = TituloProfessor.find_by_sql("SELECT * FROM titulo_professors tp inner join titulacaos t on tp.titulo_id=t.id where tp.professor_id=" + $professor + " and t.tipo = '5 ANOS'")
    $zerar = 0
    if $professor == '' then

    render :update do |page|
      page.replace_html 'tempo', :text => ''
      page.replace_html 'consultas', :text => ''
    end

    else
    render :update do |page|

      page.replace_html 'tempo', :partial => 'exibicao_pontuatempservico'
    end
    end
  end


  def executar
    render :partial => 'executar'
  end

  def relatorio
    render :partial => 'relatorios'
  end

  def impressao
    @professors = Professor.all
    render :partial => 'relatorio_professors'
  end
protected

  def load_funcao
    @funcao = Professor.find(:all, :order => 'funcao')
  end

  def load_professorsnome
    @professorsnome = Professor.find(:all, :order => "nome")
  end

  def load_prof_titulos
    @prof_titulos = Titulacao.find(:all, :order => 'descricao')
  end

  def load_titulos
    @titulos = Titulacao.find(:all, :order => "descricao")
  end

  def load_regiaos
    @regiaos = Regiao.find(:all, :order => "nome")
  end


  def load_unidades
    @unidades = Unidade.find(:all, :order => "nome", :include => "regiao")
  end


  def sede_unidade
    if current_user.regiao_id == 53 or current_user.regiao_id == 52 then
      @unidade_sede = Unidade.find(:all, :include => "regiao")
    else
      @unidade_sede = Unidade.find(:all, :conditions => ['id = ' + current_user.regiao_id.to_s + ' or id = 54'], :include => "regiao")
    end
  end

  def load_calculos
  end


  def load_trabalhados
    @trabalhados = Trabalhado.find(:all)

  end

  def load_titulo_professor
    @titulo_professor = TituloProfessor.find(:all)
  end


  def load_titulacao
    @titulacaos = Titulacao.find(:all)
  end

  def load_acum_trab
    @acum_trab = AcumTrab.find(:all, :include => "professor")
  end



end