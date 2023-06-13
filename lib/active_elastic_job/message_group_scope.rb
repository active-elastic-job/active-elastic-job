module ActiveElasticJob
  class MessageGroupScope
    @@message_group_suffix = Concurrent::ThreadLocalVar.new { [] }

    def self.message_group_suffix
      @@message_group_suffix.value.last
    end

    def self.scope(message_group_suffix, &block)
      @@message_group_suffix.value.push(message_group_suffix)
      output = block.call
      @@message_group_suffix.value.pop
      output
    end
  end
end
