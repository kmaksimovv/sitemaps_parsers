require 'nokogiri'
require 'open-uri'
require 'uri'
require 'net/http'

require 'sitemaps_parsers/version'

class SitemapParser
  attr_reader :domain, :robots_sitemap_path, :list_nested_sitemap

  def initialize(domain)
    @domain = domain
    @url = URI.parse("http://#{@domain}")
  end

  def urls
    return parse_sitemap(check_default_sitemap) if check_default_sitemap

    parse_nested_sitemaps(robots_sitemap)
  end

  def sitemap_path
    robots_sitemap
    check_default_sitemap&.to_s || robots_sitemap_path&.join(',')
  end

  private

  def check_default_sitemap
    url_http_sitemap = URI.join(@url, 'sitemap.xml')
    url_https_sitemap = URI.join(URI.parse("https://#{@domain}"), 'sitemap.xml')
    url_http_www_sitemap = URI.join(URI.parse("http://www.#{@domain}"), 'sitemap.xml')
    url_https_www_sitemap = URI.join(URI.parse("https://www.#{@domain}"), 'sitemap.xml')

    return url_http_sitemap if Net::HTTP.get_response(url_http_sitemap).code == '200'
    return url_https_sitemap if Net::HTTP.get_response(url_https_sitemap).code == '200'
    return url_http_www_sitemap if Net::HTTP.get_response(url_http_www_sitemap).code == '200'
    return url_https_www_sitemap if Net::HTTP.get_response(url_https_www_sitemap).code == '200'
  rescue StandardError
    nil
  end

  def robots_sitemap
    @robots_sitemap_path ||= open(URI.join(@url, 'robots.txt')).read.scan(/\s*sitemap:\s*([^\r\n]+)\s*$/i).flatten!.uniq

    @list_nested_sitemap ||= nested_sitemaps(@robots_sitemap_path)
    @list_nested_sitemap
  rescue StandardError
    nil
  end

  def nested_sitemaps(sitemap_list = [])
    sitemap_list.map do |path|
      path_io = open(path)
      Nokogiri::HTML(path_io).xpath('//sitemapindex/sitemap/loc').map(&:text)
    end.flatten
  end

  def parse_nested_sitemaps(nested_sitemaps = [])
    nested_sitemaps.map do |sitemap|
      Nokogiri::XML(load_sitemap(sitemap))
    end.compact.map do |sitemap_io|
      filter_sitemap_urls(sitemap_io)
    end.compact.flatten
  end

  def load_sitemap(url = nil)
    sitemap_io = open(url)
  rescue StandardError
    nil
  else
    begin
      return Zlib::GzipReader.new(sitemap_io)
    rescue StandardError
      return sitemap_io
    end
  end

  def filter_sitemap_urls(sitemap_data)
    sitemap_data.search('url').map { |url| url.at('loc').content.strip }
  end

  def parse_sitemap(url)
    sitemap_data = Nokogiri::XML(open(url))

    if sitemap_data.at('urlset').present?
      return filter_sitemap_urls(sitemap_data.at('urlset'))

    elsif sitemap_data.at('sitemapindex').present?
      found_urls = []
      nested_sitemaps = sitemap_data.at('sitemapindex').search('sitemap')

      nested_sitemaps.each do |sitemap|
        child_sitemap_location = sitemap.at('loc').content.strip
        found_urls << filter_sitemap_urls(Nokogiri::XML(open(child_sitemap_location)))
      end
      return found_urls.flatten
    end
  end
end
