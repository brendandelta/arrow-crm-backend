module EncryptedAttributes
  extend ActiveSupport::Concern

  class_methods do
    # Define an encrypted attribute with automatic ciphertext storage and last4 extraction
    #
    # Usage in model:
    #   encrypted_attribute :ein, last_count: 4
    #   encrypted_attribute :routing_number, last_count: 4
    #   encrypted_attribute :account_number, last_count: 4
    #
    # This creates:
    #   - set_ein(value) - encrypts and stores
    #   - ein_decrypted - returns decrypted value (use with caution!)
    #   - ein_masked - returns "••••1234" format
    #   - ein_last4 - direct access to last4 column
    #
    def encrypted_attribute(name, last_count: 4)
      ciphertext_column = "#{name}_ciphertext"
      last4_column = "#{name}_last4"

      # Setter method
      define_method("set_#{name}") do |value|
        if value.blank?
          self[ciphertext_column] = nil
          self[last4_column] = nil
        else
          result = Security::Encryption.encrypt_with_last4(value, last_count: last_count)
          self[ciphertext_column] = result[:ciphertext]
          self[last4_column] = result[:last4]
        end
      end

      # Decrypted getter (use sparingly, requires authorization)
      define_method("#{name}_decrypted") do
        Security::Encryption.decrypt(self[ciphertext_column])
      end

      # Masked getter (safe to display)
      define_method("#{name}_masked") do
        last4 = self[last4_column]
        return nil if last4.blank?
        "••••#{last4}"
      end

      # Check if value is present
      define_method("#{name}_present?") do
        self[ciphertext_column].present?
      end

      # Alias for last4 access
      define_method("#{name}_last4") do
        self[last4_column]
      end
    end
  end
end
