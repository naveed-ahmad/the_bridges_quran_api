class Ayah < ApplicationRecord
  has_many :bookmarks, dependent: :delete_all
  attr_writer :texts, :html
  
  def add_text(text)
    @texts ||= []
    @texts << text
  end
  
  def add_html(_html)
    @html ||= []
    
    @html << _html
  end
  
  def full_text
    @texts.join ''
  end
  
  def full_html
    @html.join ''
  end
end
