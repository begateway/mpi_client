module MPI
  module Verification
    class Request
      PARAMS_MAP = {
        'AccountId'       => :account_id,
        'Amount'          => :amount,     #in cents
        'CardNumber'      => :card_number,
        'Description'     => :description,
        'DisplayAmount'   => :display_amount,
        'CurrencyCode'    => :currency,
        'ExpY'            => :exp_year,
        'ExpM'            => :exp_month,
        'URL'             => :termination_url,
      }

      REQUEST_TYPE = 'vereq'

      attr_reader :options, :transaction_id

      def initialize(options, transaction_id)
        @options, @transaction_id = options, transaction_id
      end

      def process
        Response.parse(post(build_xml))
      end

      private
      def post(xml_request)
        Network.post(MPI.server_url, xml_request)
      end

      def build_xml
        xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8')

        xml.REQUEST(:type => REQUEST_TYPE) do |xml|
          xml.Transaction(:id => transaction_id) do |xml|
            PARAMS_MAP.each_pair do |key, value|
              xml.send(key, options[value])
            end
          end
        end

        xml.to_xml
      end
    end
  end
end
