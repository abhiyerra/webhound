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

      link =~ /^(https?:\/\/)([0-9A-Za-z_\.:]+)(.*)/

      http = $1  
      uri = $2
      path = $3

      new_link = http

      if link =~ /^https?/
        # Full url. ex. http://google.com or http://google.com/basdasd
        new_link = link
      elsif link =~ /^\/(.*)/
        # ex. /test/test
        # TODO: Deal with cases like:
          # /test/test/ - don't want t add an extra /
          # /test/test?test=test - stop at ?
        new_link = page_http + page_uri + '/' + $1
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
$queue = start_url

start_crawling
