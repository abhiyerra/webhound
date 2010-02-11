require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'mongo'

$db = Mongo::Connection.new.db("crawler")
$crawled = $db['crawled']

$queue = []
$queue_failed = []

def crawler page
  begin
    return if $crawled.find_one({ "url" => page })


    # TODO: Minimize these.
    return if $queue_failed.include? page

    doc = Nokogiri::HTML(open(page))

    page =~ /^(https?:\/\/)([0-9A-Za-z_\.:]+)(.*)/
    page_http = $1
    page_uri = $2
    page_path = $3

    doc_i = { "url" => page, "content" => doc.text }
    $crawled.insert(doc_i)

    doc.search('a').each do |l|
      link = l.attributes['href'].to_s

      link =~ /^(https?:\/\/)([0-9A-Za-z_\.:]+\/)(.*)/

      http = $1  
      uri = $2
      path = $3
      # TODO: params

      new_link = ''

      # Ignore these conditions
      next if link =~ /^#.*/ #|| link =~ // || link =~ /javascript.*/

      if link =~ /^https?/
        # Full url. ex. http://google.com or http://google.com/basdasd
        new_link = link
      elsif link =~ /^\/(.*)\/$/
        # /test/test/ - don't want t add an extra /
        new_link = page_http + page_uri + '/' + $1
      elsif link =~ /^\/(.*)/
        # ex. /test/test
        new_link = page_http + page_uri + '/' + $1

        # TODO: Deal with cases like basically parameters
          # /test/test?test=test - stop at ?
          # test - 
      elsif link =~ /^[^\/]?(.*)/
        #puts "here"
        new_link = page + (page =~ /.*\/$/ ? '' : '/') + link
        #puts new_link
      elsif link =~ /^mailto:(.*)/
        email = $1
        # TODO: Do stuff with email.
      else
        new_link = page + "/" + link
      end

      $queue << new_link
    end
 rescue
   puts page
   $queue_failed << page
 end
end

def start_crawling
  while !$queue.empty?
    page = $queue.first
    $queue.shift
    
    crawler page
  end
end

start_urls = ['http://www.berkeley.edu/']
$queue = start_urls

start_crawling
