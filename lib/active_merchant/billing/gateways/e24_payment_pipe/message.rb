require 'uri'
require 'net/http'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module E24PaymentPipe

      # Messages connections between client and server

      class Message
        MESSAGE_FIELDS = [ :id, :password, :password_hash, :amount, :currency_code, :action, :lang_id, :response_url,
                           :error_url, :track_id, :trans_id, :payment_id, :udf1, :udf2, :udf3, :udf4, :udf5 ].freeze

        FIELDS_MAP = {
          :amount        => 'amt',
          :response_url  => 'responseURL',
          :error_url     => 'errorURL'
        }.freeze

        SERVLET = {
          :payment     => 'PaymentInitHTTPServlet',
          :transaction => 'PaymentTranHTTPServlet'
        }.freeze

        def initialize(params)
          @web_address = params[:web_address]
          @port     = params[:port]
          @context  = params[:context]

          @fields = {}

          MESSAGE_FIELDS.each do |field|
            name = FIELDS_MAP.has_key?(field) ? FIELDS_MAP[field] : field
            name = name.to_s.gsub('_','')

            @fields[name] = params[field] if params.has_key?(field)
          end

          raise E24PaymentPipe::MessageError, "No Url specified" if @web_address.blank?
          raise E24PaymentPipe::MessageError, "No port specified" if @port.blank?
        end

        # Send settings (hash) to server via post.
        def send(option = :payment)
          uri = URI.parse(create_message_url(option))
          uri.query = URI.encode_www_form(@fields)

          raise MessageError, "No data to post" if uri.query.blank?

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.path)
          request.body = uri.query

          response = http.start {|http| http.request(request) }
          response.body
        end

        def create_message_url(option)
          from = ''

          # check if need ssl support
          from << (@port == '443' ? 'https://' : 'http://')

          # append web address
          from << @web_address

          # append port
          from << ':' << @port

          # append context
          if @context.blank?
            from << '/'
          else
            from << '/' unless @context.start_with?('/')
            from << context
            from << '/' unless @context.end_with?('/')
          end

          raise MessageError, 'Wrong message option' if SERVLET[option].blank?

          # finish up the from web url
          from << 'servlet/'
          from << SERVLET[option]
        end
      end
    end
  end
end
