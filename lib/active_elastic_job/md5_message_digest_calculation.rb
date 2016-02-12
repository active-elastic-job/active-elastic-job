require 'openssl'
module ActiveElasticJob
  # This module provides methods that calculate the MD5 digest for Amazon
  # SQS message bodies and message attributes.
  # The digest can be used to verify that Amazon SQS received the message
  # correctly.
  #
  # Example:
  #
  #   extend ActiveElasticJob::MD5MessageDigestCalculation
  #
  #   resp = Aws::SQS::Client.new.send_message(
  #     queue_url: queue_url,
  #     message_body: body,
  #     message_attributes: attributes
  #   )
  #
  #   if resp.md5_of_message_body != md5_of_message_body(body)
  #     raise "Returned digest of message body is invalid!"
  #   end
  #
  #   if resp.md5_of_message_attributes != md5_of_message_attributes(attributes)
  #     raise "Returned digest of message attributes is invalid!"
  #   end
  module MD5MessageDigestCalculation
    TRANSPORT_TYPE_ENCODINGS = {
      'String' => 1,
      'Binary' => 2,
      'Number' => 1
    }

    CHARSET_ENCODING = Encoding::UTF_8

    # Returns MD5 digest of +message_body+.
    def md5_of_message_body(message_body)
      OpenSSL::Digest::MD5.hexdigest(message_body)
    end

    # Returns MD5 digest of +message_attributes+.
    #
    # The calculation follows the official algorithm which
    # is specified by Amazon.
    def md5_of_message_attributes(message_attributes)
      encoded = message_attributes.each.with_object({ }) do |(name, v), hash|
        hash[name.to_s] = ""
        data_type = v['data_type'] || v[:data_type]

        hash[name.to_s] << encode_length_and_bytes(name.to_s) <<
          encode_length_and_bytes(data_type) <<
          [ TRANSPORT_TYPE_ENCODINGS[data_type] ].pack('C')

        if string_value = v['string_value'] || v[:string_value]
          hash[name.to_s] << encode_length_and_string(string_value)
        elsif binary_value = v['binary_value'] || v[:binary_value]
          hash[name.to_s] << encode_length_and_bytes(binary_value)
        end
      end

      buffer = encoded.keys.sort.reduce("") do |b, name|
        b << encoded[name]
      end
      OpenSSL::Digest::MD5.hexdigest(buffer)
    end

    private

    def encode_length_and_string(string)
      return '' if string.nil?
      string = String.new(string)
      string.encode!(CHARSET_ENCODING)
      encode_length_and_bytes(string)
    end

    def encode_length_and_bytes(bytes)
      return '' if bytes.nil?
      [ bytes.bytesize, bytes ].pack("L>a#{bytes.bytesize}")
    end
  end
end
