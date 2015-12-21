#!/bin/env ruby
# encoding: utf-8

require 'rest-client'
require 'scraperwiki'
require 'wikidata/fetcher'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'


def noko_for(url)
  Nokogiri::HTML(open(URI.escape(URI.unescape(url))).read) 
end

def wikinames_from(url)
  noko = noko_for(url)
  noko.css('#Mesa_Diretora_2').xpath('following::*').remove
  
  names = noko.xpath('//table//th[contains(.,"Nome")]').map do |th|
    wantcol = th.xpath("ancestor::tr").last.css('th').find_index { |th| th.text.to_s.include? 'Nome' }
    th.xpath("ancestor::table").last.xpath(".//td[#{wantcol + 1}]//a[not(@class='new')]/@title").map { |t| t.text }
  end
  raise "No names found in #{url}" if names.count.zero?
  return names
end

def fetch_info(names)
  WikiData.ids_from_pages('pt', names).each do |name, id|
    data = WikiData::Fetcher.new(id: id).data('pt') rescue nil
    unless data
      warn "No data for #{p}"
      next
    end
    data[:original_wikiname] = name
    ScraperWiki.save_sqlite([:id], data)
  end
end

fetch_info wikinames_from('https://pt.wikipedia.org/wiki/Lista_de_deputados_federais_do_Brasil_da_55.%C2%AA_legislatura')

warn RestClient.post ENV['MORPH_REBUILDER_URL'], {} if ENV['MORPH_REBUILDER_URL']

