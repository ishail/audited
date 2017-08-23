require 'active_record'

module Audited
  class << self
    attr_accessor :ignored_attributes, :current_user_method, :audit_class, :auditing_enabled, :audit_encryption_salt, :doc_callback_method

    def audit_class
      @audit_class || Audit
    end

    def store
      Thread.current[:audited_store] ||= {}
    end

    def config
      yield(self)
    end
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)

  @current_user_method = :current_user

  module Helper
    def self.encrypt_audited_column(input_word, encryption_key)
      return "" if input_word.blank?

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc').encrypt
      cipher.key = Digest::SHA1.hexdigest encryption_key
      encrypted = cipher.update(input_word) + cipher.final
      Base64.encode64(encrypted).encode('utf-8')
    end

    def self.decrypt_audited_column(input_word, encryption_key)
      return "" if input_word.blank?

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc').decrypt
      cipher.key = Digest::SHA1.hexdigest encryption_key

      decoded = Base64.decode64 encoded.encode('ascii-8bit')
      decrypted = cipher.update(decoded)
      decrypted << cipher.final
    end
  end
end

require 'audited/auditor'
require 'audited/audit'

::ActiveRecord::Base.send :include, Audited::Auditor

require 'audited/sweeper'
