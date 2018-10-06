namespace :parser do
  $RUK               = true
  $foot_note_counter = 0
  $chapter = 10
  ## 7
  # $ayah_container_key = ".c28 .c37"
  # $sup_class = "c9"
  # $highlight_class= "c8"
  # $ayah_number_class = 'c1'
  
  # 8
  # $ayah_container_key = ".c26 .c24"
  # $sup_class = "c6"
  # $highlight_class= "c9"
  # $ayah_number_class = 'c8'


  # 9
  #$ayah_container_key = ".c26 .c6"
  #$sup_class = "c0"
  #$highlight_class= "c5"
  #$ayah_number_class = 'c3' # c2 and c3

  # 10
  $ayah_container_key = ".c21 .c22"
  $sup_class = "c2"
  $highlight_class= "c11" # c11 and c3
  $ayah_number_class = 'c5' # c2 and c3


  def parse_footnote(dom, footnote)
    if dom.children.count == 1
      if dom.name != 'a'
        text = dom.children.first.text
        footnote.add_text(text)
      end
    else
      dom.children.each do |_dom|
        parse_footnote(_dom, footnote)
      end
    end
    
    footnote
  end
  
  def parse_dom(dom, ayah = nil)
    if dom.children.count == 1 #&& dom.children.first.class == Nokogiri::XML::Text
      #
      # we've reached to leaf node. Check if its ayah number or text
      #
      
      text = dom.children.first.text.to_s.gsub("&nbsp;", '')
      html = dom.children.to_s
      
      if dom.attr('class').to_s.include?($sup_class)
        # superscripts
        text = text.gsub(/\[\d*\]/, '').strip
        
        if text.present?
          text = "<a class='sup'><sup>#{text.strip}</sup></a>"
        end
      end
      
      if dom.attr('class').to_s.include?($highlight_class)
        # red highlighted text
        text = text.gsub(/\[\d*\]/, '').strip
        if text.present?
          text = "<span class='h'>#{text.gsub("&nbsp;", ' ').strip}</span>"
        end
      end
      
      if dom.children.first.attr('href').present?
        id         = dom.children.first.attr('href')
        parent_dom = $doc.search(id).first.parent
        foot_note  = Bookmark.new(ayah: ayah)
        
        foot_note = parse_footnote(parent_dom, foot_note)
        foot_note_text = foot_note.full_text.gsub(/\[\d*\]/, '').strip

        if foot_note_text.present?
          foot_note.text = foot_note_text
          foot_note.save
          text = "<a class='f'><sup f=#{foot_note.id}>#{$foot_note_counter += 1}</sup></a>"
        end
      end
      
      if text.include?('[') && $RUK
        binding.pry
      end
      
      if text.to_i > 0 || dom.attr('class').to_s.include?($ayah_number_class)
        # ayah number
        ayah_number = text.gsub("&nbsp;", '').gsub(/\D/, '')
        key         = "#{$chapter}:#{ayah_number}"
        
        if !ayah
          ayah = Ayah.find_or_initialize_by(ayah_key: key)
          puts ayah.ayah_key
          ayah.save
        else
          # save previous ayah
          # and processed to next ayah
          ayah.text      = ayah.full_text
          ayah.text_html = ayah.full_html
          
          ayah.save
          ayah = Ayah.find_or_initialize_by(ayah_key: key)
          ayah.save
          $foot_note_counter = 0
        end
      else
        if (_t = text.gsub("&nbsp;", '')).presence
          ayah.add_text(_t)
          ayah.add_html(html)
        end
      end
    else
      dom.children.each do |_dom|
        parse_dom(_dom, ayah)
      end
    end
    
    ayah
  end
  
  task parse: :environment do
    binding.pry
    Ayah.where("ayah_key like '#{$chapter}:%'").destroy_all
    
    $doc = Nokogiri.parse(File.read("data/#{$chapter}.html"))
    ayah = nil
    $doc.search($ayah_container_key).each do |group|
      group.children.each do |parent_dom|
        ayah = parse_dom(parent_dom, ayah)
      end
    end
    
    ayah.text      = ayah.full_text
    ayah.text_html = ayah.full_html
    
    ayah.save
  end
end
