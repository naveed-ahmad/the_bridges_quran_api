class CreateBookmarks < ActiveRecord::Migration[5.2]
  def change
    create_table :bookmarks do |t|
      t.integer :ayah_id
      t.text :text
      t.string :tags
      t.text :text_html

      t.timestamps
    end
  end
end
