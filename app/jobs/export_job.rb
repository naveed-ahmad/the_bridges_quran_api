class ExportJob < ApplicationJob
  queue_as :default
  STORAGE_PATH = "public/exported_bridges"
  
  def perform(original_file_name = nil)
    original_file_name ||= 'bridges.db'
    
    file_name = original_file_name.chomp('.db')
    file_path = "#{STORAGE_PATH}/#{Time.now.to_i}"
    require 'fileutils'
    FileUtils::mkdir_p file_path
    
    copy_default_db "#{file_path}/#{file_name}.db"
    prepare_db("#{file_path}/#{file_name}.db")
    
    prepare_import_sql
    
    # zip the file
    `bzip2 #{file_path}/#{file_name}.db`
    
    # return the db file path
    "#{file_path}/#{file_name}.db.bz2"
  end
  
  def copy_default_db(new_path)
    FileUtils.cp 'data/simple_db/bridges.db', new_path
  end
  
  def prepare_db(file_path)
    BTranslation.establish_connection connection_config(file_path)
    BFootnote.establish_connection connection_config(file_path)
    BAyah.establish_connection connection_config(file_path)
    
    BTranslation.connection.execute "CREATE TABLE translations(id integer, ayah_key string, text text, ayah_id integer, primary key(id))"
    BFootnote.connection.execute "CREATE TABLE footnotes(translation_id integer, text text, id integer, primary key(id))"
    
    BTranslation.table_name = 'translations'
    BFootnote.table_name    = 'footnotes'
    BAyah.table_name = 'ayah'
  end
  
  def prepare_import_sql()
    translation_id_seq = 1
    # Simplify this! don't use verse table from community

    Ayah.find_each do |ayah|
      puts ayah.ayah_key
      
      translation = BTranslation.create({
                                          ayah_id:  BAyah.find_by_ayah_key(ayah.ayah_key).id,
                                          ayah_key: ayah.ayah_key,
                                          text:     ayah.text,
                                          id:       translation_id_seq += 1
                                        })
      
      ayah.bookmarks.each do |footnote|
        BFootnote.create({
                           translation_id: translation.id,
                           id:             footnote.id,
                           text:           footnote.text
                         })
      end
    end
  end
  
  def connection_config(file_name)
    { adapter:  'sqlite3',
      database: file_name
    }
  end
  
  class BTranslation < ActiveRecord::Base
  end
  
  class BFootnote < ActiveRecord::Base
  end

  class BAyah < ActiveRecord::Base
  end
end
