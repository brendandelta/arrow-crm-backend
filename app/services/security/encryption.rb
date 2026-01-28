module Security
  class Encryption
    class << self
      # Get the encryptor instance (memoized per request cycle)
      def encryptor
        @encryptor ||= begin
          key = master_key
          raise "ENCRYPTION_MASTER_KEY environment variable is not set" if key.blank?

          # Ensure key is properly formatted (32 bytes for AES-256)
          derived_key = ActiveSupport::KeyGenerator.new(key).generate_key('arrow-crm-encryption', 32)
          ActiveSupport::MessageEncryptor.new(derived_key)
        end
      end

      # Encrypt a plaintext value
      def encrypt(plaintext)
        return nil if plaintext.blank?
        encryptor.encrypt_and_sign(plaintext)
      end

      # Decrypt a ciphertext value
      def decrypt(ciphertext)
        return nil if ciphertext.blank?
        encryptor.decrypt_and_verify(ciphertext)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage => e
        Rails.logger.error("[Security::Encryption] Decryption failed: #{e.class}")
        nil
      end

      # Extract last N characters from a value (for masking display)
      def extract_last(value, count = 4)
        return nil if value.blank?
        value.to_s.last(count)
      end

      # Generate a masked display value
      def mask(value, show_last: 4, mask_char: '•')
        return nil if value.blank?
        last_chars = value.to_s.last(show_last)
        mask_char * 4 + last_chars
      end

      # Encrypt and return both ciphertext and last4
      def encrypt_with_last4(plaintext, last_count: 4)
        return [nil, nil] if plaintext.blank?

        # Clean the value (remove spaces, dashes for numbers)
        cleaned = plaintext.to_s.gsub(/[\s\-]/, '')

        {
          ciphertext: encrypt(cleaned),
          last4: extract_last(cleaned, last_count)
        }
      end

      private

      def master_key
        ENV.fetch('ENCRYPTION_MASTER_KEY') do
          # In development/test, use Rails master key as fallback
          if Rails.env.development? || Rails.env.test?
            Rails.application.credentials.secret_key_base&.first(32) ||
              'development-only-key-not-for-production'
          else
            raise "ENCRYPTION_MASTER_KEY must be set in production"
          end
        end
      end
    end
  end
end
