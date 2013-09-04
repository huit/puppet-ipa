module Puppet::Parser::Functions
  newfunction(:ipa_string2hash, :type => :rvalue, :doc => 'This function converts a comma delimited string separated by a colon into a hash. ex. "string1,string2:string3,string4"') do |arguments|
    if arguments.size != 1
      raise(Puppet::ParseError, "suffix(): Wrong number of arguments " + "given (#{arguments.size} for 1)")
    else
      packed = arguments[0]
      hashed = {}
        unless packed.is_a?(String)
          raise(Puppet::ParseError, 'ipa_string2hash(): Requires string to work with')
        end
      grouped = packed.split(":").group_by { |s| s.split(",")[1] }
      hashed = Hash[grouped.map { |d, str| [d, str.map { |s| s.split(",")[0] }] }]
    end
  return hashed
  end
end
