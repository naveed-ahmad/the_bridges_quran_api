class Bookmark < ApplicationRecord
  belongs_to :ayah
  
  attr_writer :texts
  
  def add_text(text)
    @texts ||= []
    @texts << text
  end
  
  def full_text
    @texts ||= []
  
    @texts.join ''
  end
end
