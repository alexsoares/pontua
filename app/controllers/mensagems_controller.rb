class MensagemsController < ApplicationController
  before_filter :load_users
  # GET /mensagems
  # GET /mensagems.xml
  def index
    @mensagems = Mensagem.all(:conditions => ['para = ?', current_user.id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mensagems }
    end
  end

  def saida
    @mensagems = Mensagem.all(:conditions => ['user_id = ?', current_user.id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mensagems }
    end
  end

  def entrada
    @mensagems = Mensagem.all(:conditions => ['para = ?', current_user.id])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mensagems }
    end

  end

  # GET /mensagems/1
  # GET /mensagems/1.xml
  def show
    @mensagem = Mensagem.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mensagem }
    end
  end

  # GET /mensagems/new
  # GET /mensagems/new.xml
  def new
    @mensagem = Mensagem.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mensagem }
    end
  end

  # GET /mensagems/1/edit
  def edit
    @mensagem = Mensagem.find(params[:id])
  end

  # POST /mensagems
  # POST /mensagems.xml
  def create
    @mensagem = Mensagem.new(params[:mensagem])
    @mensagem.user_id = current_user.id
    teste = @mensagem.created_at
    respond_to do |format|
      if @mensagem.save
        flash[:notice] = 'Mensagem was successfully created.'
        format.html { redirect_to(@mensagem) }
        format.xml  { render :xml => @mensagem, :status => :created, :location => @mensagem }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mensagem.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mensagems/1
  # PUT /mensagems/1.xml
  def update
    @mensagem = Mensagem.find(params[:id])

    respond_to do |format|
      if @mensagem.update_attributes(params[:mensagem])
        flash[:notice] = 'Mensagem was successfully updated.'
        format.html { redirect_to(@mensagem) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mensagem.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mensagems/1
  # DELETE /mensagems/1.xml
  def destroy
    @mensagem = Mensagem.find(params[:id])
    @mensagem.destroy

    respond_to do |format|
      format.html { redirect_to(mensagems_url) }
      format.xml  { head :ok }
    end
  end

  private

  def load_users
    @user_de = User.all(:conditions => ['id = ?', current_user.id])
    @user_para = User.all
  end

end
