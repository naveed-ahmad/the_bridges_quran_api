class CreateAyahs < ActiveRecord::Migration[5.2]
  def change
    create_table :ayahs do |t|
      t.string :ayah_key
      t.text :text
      t.text :text_html
      
      t.timestamps
    end
  end
end
