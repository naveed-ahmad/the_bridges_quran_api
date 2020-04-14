namespace :parser do
  $parent_doc = nil
  $RUK = true
  $foot_note_counter = 0
  $white_space = " "
  $qirat_class = 'c10'
  # 10
  $ayah_container_key = ".c17"
  $sup_class = "c0"
  $highlight_class = "c5" # c11 and c3
  $ayah_number_class = 'c4' # c2 and c3
  $italic = 'c1'

  def parse_footnote(dom, footnote)
    if dom.children.count == 1
      if dom.name != 'a'
        text = dom.children.first.text.strip

        if text[0] == $white_space
          text = text.gsub(/\u00A0/, '')
        end

        if dom.attr('class').to_s.include?($qirat_class)
          text = "<b class=h>#{'Q' == text ? 'Qirat' : text}</b>"
        end

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

      text = dom.children.first.text.to_s.gsub("&nbsp;", " ")
      html = dom.children.to_s

      if dom.attr('class').to_s.include?($sup_class)
        # superscripts
        text = text.gsub(/\[\d*\]/, '').strip

        if text.present?
          text = "<a class='sup'><sup>#{text.strip}</sup></a>"
        end
      end

      if dom.attr('class').to_s.include?($italic)
        if text.present?
          text = "<i class=s>#{text.gsub("&nbsp;", '').strip}</i>"
        end
      end

      if dom.attr('class').to_s.include?($highlight_class)
        # red highlighted text
        text = text.gsub(/\[\d*\]/, '').strip
        if text.present?
          text = "<span class=h>#{text.gsub("&nbsp;", '').strip}</span>"
        end
      end

      if dom.children.first.attr('href').present?
        id = dom.children.first.attr('href')
        parent_dom = $parent_doc.search(id).first.ancestors('div').first
        foot_note = Bookmark.new(ayah: ayah)

        foot_note = parse_footnote(parent_dom, foot_note)
        foot_note_text = foot_note.full_text.gsub(/\[\d*\]/, '').strip

        if foot_note_text.present?
          if foot_note_text[0] == $white_space
            foot_note_text = foot_note_text.gsub(/\u00A0/, '')
          end

          foot_note.text = foot_note_text
          foot_note.save
          text = "<a class=f><sup f=#{foot_note.id}>#{$foot_note_counter += 1}</sup></a>"
        end
      end

      #if text.include?('[') && $RUK
      #  binding.pry
      #end

      if text.to_i > 0 || dom.attr('class').to_s.strip.include?($ayah_number_class)
        # ayah number
        ayah_number = text.gsub("&nbsp;", '').gsub(/\D/, '')
        key = "#{$chapter}:#{ayah_number}"

        if !ayah
          ayah = Ayah.find_or_initialize_by(ayah_key: key)
          puts "Init #{ayah.ayah_key}"

          ayah.save
        else
          # save previous ayah
          # and processed to next ayah

          ayah_text = ayah.full_text
          if ayah_text[0] == $white_space
            ayah_text = ayah_text.gsub(/\u00A0/, '')
          end

          ayah.text = ayah_text.strip
          ayah.text_html = ayah.full_html

          ayah.save
          ayah = Ayah.find_or_initialize_by(ayah_key: key)
          ayah.save
          puts ayah.ayah_key

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
    #Ayah.delete_all
    #Bookmark.delete_all

    $parent_doc = Nokogiri::HTML.parse(File.read("data/QuranBridge.html"))
    1.upto(114) do |c|
      $chapter = c
      $foot_note_counter = 0

      text = "<div>#{File.read("data/chapters/#{$chapter}.html")}</div>"

      $doc = Nokogiri::HTML.parse(text) #Nokogiri.parse(text)
      ayah = nil

      $doc.search($ayah_container_key).each do |group|
        group.children.each do |parent_dom|
          ayah = parse_dom(parent_dom, ayah)
        end
      end

      ayah_text = ayah.full_text
      if ayah_text[0] == $white_space
        ayah_text = ayah_text.gsub(/\u00A0/, '')
      end

      ayah.text = ayah_text.strip
      ayah.text_html = ayah.full_html

      ayah.save
    end
  end
end
