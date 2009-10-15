require 'rubygems'
require 'network'
require 'nokogiri'

$:.unshift File.dirname(__FILE__)

require 'mpi_client/option_translator'
require 'mpi_client/mpi_response'

class MPIClient
  CLIENT_METHODS = %w(create_account get_account_info update_account delete_account enrolled)

  def initialize(server_url)
    @connection = Network::Connection.new(server_url)
  end

  def method_missing(method, *args)
    submit_request(method, *args) if CLIENT_METHODS.include?(method.to_s)
  end

  private
  def submit_request(request_type, *args)
    parse_response(@connection.post(prepare_request_data(request_type, *args)))
  end

  def prepare_request_data(request_type, options, transaction_attrs = {})
    options = options.dup
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.REQUEST(:type => request_type) do |xml|
        xml.Transaction(transaction_attrs) do |xml|
          options.each { |k,v|  xml.send(OptionTranslator.to_server(k), v) }
        end
      end
    end

    builder.to_xml
  end

  def parse_response(response_data)
    doc = Nokogiri::XML(response_data)

    if error = doc.xpath("//Error").first
      response = {
        :error_message => error.text,
        :error_code    => error[:code]
      }
    else
      response = Hash[*doc.xpath("//Transaction/*").collect{|a| [OptionTranslator.to_client(a.name.to_sym), a.text] }.flatten]
    end

    MPIResponse.new(response)
  end
end
