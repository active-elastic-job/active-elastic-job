module ActiveElasticJob
  module VERSION
    MAJOR = 3
    MINOR = 2
    TINY  = 0
    PRE   = 'pre'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

    def self.to_s
      STRING
    end
  end

  def self.version
    VERSION::STRING
  end
end
