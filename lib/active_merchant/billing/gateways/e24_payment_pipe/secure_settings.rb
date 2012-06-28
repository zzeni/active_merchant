require 'tempfile'
require 'zip/zip'
require 'base64'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module E24PaymentPipe

      # Extracts the secure data found in resource file.
      #
      # You need to set an alias, if not, an errors is going to be raised.

      class SecureSettings

        # Open resource file and create a readable one. Error thrown if no resource
        # file is found or alias options is not set.
        #
        # Options:
        #
        # - <tt>:resource_file</tt>   - Set the path to the resource file.
        # - <tt>:alias</tt>           - Set the merchant alias.

        def initialize(options = {})
          @resource_file    = options[:resource_file]
          @readable_file    = Tempfile.new(random_file_name)
          @alias            = options[:alias]

          raise E24PaymentPipe::SecureSettingsError, "You need to set an alias" unless @alias
        end

        # Return the secure settings data
        def secure_data
          E24PaymentPipe::Parser.parse_settings(read_zip)
        end

        private

        def random_file_name(length = 8)
          rand(36**length).to_s(36)
        end

        def merchant_credentials_file
          @alias + '.xml'
        end

        def read_zip
          create_readable_zip

          zip_entry = nil
          xml_content = []

          zip_file = Zip::ZipFile.open(@readable_file.path)

          begin
            zip_entry = zip_file.get_entry(merchant_credentials_file)
          ensure
            zip_file.close
          end

          if !zip_file.nil?
            zip_stream = zip_file.get_input_stream(zip_entry)
          end

          zip_stream.each { |z| xml_content << z.unpack('c*') }
          result = simple_xor(xml_content.flatten).pack('c*')
          raise E24PaymentPipe::SecureSettingsError, "Empty zip file" if result.blank?

          # delete the output file
          File.delete(@readable_file.path)
          result
        end

        def create_readable_zip
          file_bytes = []

          File.open(@resource_file, 'rb') do |in_file|
            file_bytes = in_file.read.unpack('c*')
          end

          File.open(@readable_file.path, 'wb') do |out_file|
            out_file.write(simple_xor(file_bytes).pack('c*'))
          end
        end

        def simple_xor(bytes)
          str = <<-EOS.gsub(/\s+/, " ").strip
            Those who profess to favour freedom and yet depreciate agitation
            are men who want rain without thunder and lightning
          EOS

          result = []
          str_bytes = []

          str.each_byte { |b| str_bytes << b }

          i = 0
          while i != bytes.length
            str_bytes.each do |str_byte|
              result[i] = (bytes[i] ^ str_byte)
              i += 1
              break if i == bytes.length
            end
          end
          result
        end
      end
    end
  end
end
