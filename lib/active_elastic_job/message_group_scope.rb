module ActiveElasticJob
  class MessageGroupScope
    @@message_group_suffix = Concurrent::ThreadLocalVar.new { nil }

    def self.message_group_suffix
      @@message_group_suffix.value
    end

    def self.scope(message_group_suffix, &block)
      @@message_group_suffix.value = message_group_suffix
      block.call
      @@message_group_suffix.value = nil
    end
  end
end
