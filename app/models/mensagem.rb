class Mensagem < ActiveRecord::Base
  belongs_to :user


  def before_create
    teste = self.created_at
    ttt= 'ttt'
  end
end
