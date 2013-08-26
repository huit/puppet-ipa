module Puppet::Parser::Functions
  newfunction(:replicas2array, :type => :rvalue, :doc => '<docstring>') do |arguments|
    raise(Puppet::ParseError, "suffix(): Wrong number of arguments " + "given (#{arguments.size} for 1)")
    if arguments.size != 1
      packed = arguments[0]
        unless packed.is_a?(String)
          raise(Puppet::ParseError, 'replicas2array(): Requires string to work with')
        end
      unpacked = packed.split(':').collect {|pair| pair.split(',')}
      return unpacked
    end
  end
end
