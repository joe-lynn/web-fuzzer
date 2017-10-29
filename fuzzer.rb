require 'rubygems'
require 'mechanize'

def main()
  mecha = Mechanize.new
  url = 'http://127.0.0.1/dvwa/login.php'
  page = mecha.get(url)
  form = page.forms.first
  form['username'] = 'admin'
  form['password'] = 'password'
  page = form.click_button


  puts "---------------------------------------------"
  puts "DISCOVERABLE LINKS"
  puts "---------------------------------------------"

  linkList = []
  page.links.each do |link|
    if URI.parse(link.uri.to_s).host == nil
      newLink = ("http://127.0.0.1/dvwa" + "/" + link.uri.to_s).chomp(".")
      unless linkList.include? (newLink)
        linkList.push(newLink)
        puts newLink
      end
    end
  end

  visitor(mecha, linkList, 0)
  puts "---------------------------------------------"
  puts "FOUND LINKS"
  puts "---------------------------------------------"
  #guesser(mecha, linkList)
  puts "---------------------------------------------"
  puts "FOUND URL INPUT"
  puts "---------------------------------------------"
  urlInputFinder(mecha, linkList)
  puts "---------------------------------------------"
  puts "WEBPAGE"
  puts "INPUT DATA"
  puts "---------------------------------------------"
  inputLinksArray = inputFinder(linkList)
  puts "---------------------------------------------"
  puts "WEBPAGE"
  puts "COOKIE DATA"
  puts "---------------------------------------------"
  getCookies(linkList)
  puts "---------------------------------------------"
  puts "TESTING INPUTS WITH VECTOR LIST"
  puts "---------------------------------------------"
  testInputs(inputLinksArray)
  puts "---------------------------------------------"
  puts "TESTING URL INPUTS WITH VECTOR LIST"
  puts "---------------------------------------------"
  testUrlInputs(linkList)

end

def testUrlInputs(inputLinksArray)
  commonInputVectors = ['%%20d','%%20n', '%%20x', '0x7ffffffe', '0x7fffffff', '0x80000000', '0xfffffffe', '" or "a"="a', "' OR 'text' > 't'", '%22+or+isnull%281%2F0%29+%2F*', '%2A%7C', 'count(/child::node())']
  vectorLinks = Array.new
  vectorInputs = Array.new
  inputLinksArray.each do |link|
    mecha = Mechanize.new
    url = 'http://127.0.0.1/dvwa/login.php'
    page = mecha.get(url)
    form = page.forms.first
    form['username'] = 'admin'
    form['password'] = 'password'
    page = form.click_button
    begin
      if !(link.include? "logout.php")
        page = mecha.get(link)
        if page.uri.query
          stringUri = page.uri.to_s
          if !(vectorLinks.include?(stringUri))
            vectorLinks.push(stringUri.chomp(page.uri.query.to_s))
          end
          vectorInputs.push(URI::decode_www_form(page.uri.query).to_h)
        end
      end
    rescue Mechanize::ResponseCodeError, Net::HTTPNotFound
    end
  end





  vectorLinks.each do |link|
    commonInputVectors.each do |vector|
      mecha = Mechanize.new
      url = 'http://127.0.0.1/dvwa/login.php'
      page = mecha.get(url)
      form = page.forms.first
      form['username'] = 'admin'
      form['password'] = 'password'
      page = form.click_button
      begin
        if !(link.include? "logout.php")
          generatedLink = link+vector
          puts generatedLink
          page = mecha.get(generatedLink)
          #checks http
          sleep(3)
          if !(page.code.to_i == 200)
            puts "Page response code after 3 seconds is + " + page.code.to_i
          end
          #checks for sql error
          if(page.body.include?('SQL syntax;'))
            puts "Possible Sql issue found"
          end
          #checks for incorrect function
          if(page.xpath('//pre'))
            puts page.xpath('//pre')
          end
        end
      rescue Mechanize::ResponseCodeError, Net::HTTPNotFound
      end
    end
  end

end

def testInputs(inputLinksArray)
  commonInputVectors = ['%%20d','%%20n', '%%20x', '0x7ffffffe', '0x7fffffff', '0x80000000', '0xfffffffe', '" or "a"="a', "' OR 'text' > 't'", '%22+or+isnull%281%2F0%29+%2F*', '%2A%7C', 'count(/child::node())']
  inputFieldsArrayArray = Array.new
  inputLinksArray.each do |link|
    mecha = Mechanize.new
    url = 'http://127.0.0.1/dvwa/login.php'
    page = mecha.get(url)
    form = page.forms.first
    form['username'] = 'admin'
    form['password'] = 'password'
    page = form.click_button
    begin
      if !(link.include? "logout.php")
        page = mecha.get(link)
        inputFieldNameArray = Array.new
        if(page.forms.first)
          form = page.forms.first
          form.fields.each { |f| inputFieldNameArray.push(f.name)}

          inputFieldNameArray.each do |field|
            form['field'] = commonInputVectors[rand(commonInputVectors.size - 1)]
          end
          page = form.click_button
          #checks http
          sleep(3)
          if !(page.code.to_i == 200)
            puts "Page response code after 3 seconds is + " + page.code.to_i
          end
          #checks for sql error
          if(page.body.include?('SQL syntax;'))
            puts "Possible Sql issue found"
          end
          #checks for incorrect function
          if(page.xpath('//pre'))
            puts page.xpath('//pre')
          end
        end
      end
    rescue Mechanize::ResponseCodeError, Net::HTTPNotFound
    end
  end

end

def getCookies(linkList)
  mecha = Mechanize.new
  url = 'http://127.0.0.1/dvwa/login.php'
  page = mecha.get(url)
  form = page.forms.first
  form['username'] = 'admin'
  form['password'] = 'password'
  page = form.click_button
  linkList.each do |link|
    begin
      if !(link.include? "logout.php")
        page = mecha.get(link)
        puts page.uri
        puts mecha.cookies
      end
    rescue Mechanize::ResponseCodeError, Net::HTTPNotFound
    end
  end
end

def inputFinder(linkList)
  mecha = Mechanize.new
  url = 'http://127.0.0.1/dvwa/login.php'
  page = mecha.get(url)
  form = page.forms.first
  form['username'] = 'admin'
  form['password'] = 'password'
  page = form.click_button
  inputLinksArray = Array.new
  linkList.each do |link|
    begin
      if !(link.include? "logout.php")
        page = mecha.get(link)
        if(page.at("input"))
          puts page.uri
          puts page.xpath("//input")
          inputLinksArray.push(link)
        end
      end
    rescue Mechanize::ResponseCodeError, Net::HTTPNotFound

    end
  end
  return inputLinksArray
end

def urlInputFinder(mecha, linkList)
  linkList.each do |link|
    begin
      if !(link.include? "logout.php")
        page = mecha.get(link)
        if page.uri.query
          puts page.uri
          puts page.uri.query
        end
      end
    rescue Mechanize::ResponseCodeError, Net::HTTPNotFound

    end
  end
end

def guesser(mecha, linkList)
  commonWords = ["wiki", "webpage", "thumb", "img", "meta"]
  linkList.each do |link|
    commonWords.each do |word|
      begin
        if !(link.include? "logout.php")
          page = mecha.get(link+word)
          unless linkList.include? (page.uri)
            linkList.push(page.uri)
            puts page.uri
          end
        end
      rescue Mechanize::ResponseCodeError, Net::HTTPNotFound
        #intentionally does nothing. almost all of these pages should 404
      end
    end
  end

end

def visitor(mecha, linkList, ind)
  if ind < linkList.length()
    url = linkList[ind]
    if !(url.include? "logout.php")
      begin
        page = mecha.get(url)
        page.links.each do |link2|
          if !(link2.uri.to_s.include? "../")
            newLink2 = ("http://127.0.0.1/dvwa" + "/" + link2.uri.to_s).chomp(".")
            unless linkList.include? (newLink2)
              if URI.parse(link2.uri.to_s).host == nil
                linkList.push(newLink2)
                puts newLink2
              end
            end
          end
        end
      rescue Mechanize::ResponseCodeError, Net::HTTPNotFound
        puts "404!- " + "#{url}"
      end
    end

    ind += 1
    visitor(mecha, linkList, ind)
  end
end
main()