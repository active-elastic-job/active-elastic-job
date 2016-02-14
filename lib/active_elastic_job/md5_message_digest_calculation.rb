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

    NORMALIZED_ENCODING = Encoding::UTF_8

    def md5_of_message_body(message_body)
      OpenSSL::Digest::MD5.hexdigest(message_body)
    end

    def md5_of_message_attributes(message_attributes)
      encoded = { }
      message_attributes.each do |name, attribute|
        name = name.to_s
        encoded[name] = String.new
        encoded[name] << encode_length_and_bytes(name) <<
        encode_length_and_bytes(attribute[:data_type]) <<
        [TRANSPORT_TYPE_ENCODINGS[attribute[:data_type]]].pack('C'.freeze)

        if attribute[:string_value] != nil
          encoded[name] << encode_length_and_string(attribute[:string_value])
        elsif attribute[:binary_value] != nil
          encoded[name] << encode_length_and_bytes(attribute[:binary_value])
        end
      end

      buffer = encoded.keys.sort.reduce(String.new) do |string, name|
        string << encoded[name]
      end
      OpenSSL::Digest::MD5.hexdigest(buffer)
    end

    private

    def encode_length_and_string(string)
      string = String.new(string)
      string.encode!(NORMALIZED_ENCODING)
      encode_length_and_bytes(string)
    end

    def encode_length_and_bytes(bytes)
      [bytes.bytesize, bytes].pack('L>a*'.freeze)
    end
  end
end
