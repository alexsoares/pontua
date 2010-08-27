class Ficha < ActiveRecord::Base
  belongs_to :professor
  belongs_to :acum_trab
  belongs_to :trabalhado_anterior, :class_name => "Trabalhado", :foreign_key => "trabalhado_anterior_id"
  belongs_to :trabalhado_atual, :class_name => "Trabalhado", :foreign_key => "trabalhado_atual_id"


end
