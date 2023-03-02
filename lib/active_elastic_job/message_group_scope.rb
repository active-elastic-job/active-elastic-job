module ActiveElasticJob
  class MessageGroupScope
    @@message_group_suffix = Concurrent::ThreadLocalVar.new { nil }

    def self.message_group_suffix
      @@message_group_suffix.value
    end

    def scope(message_group_suffix, &block)
      @subscribers.value = message_group_suffix
      block.call
      @subscribers.value = nil
    end
  end
end
