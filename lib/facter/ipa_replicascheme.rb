Facter.add(:ipa_replicascheme) do
 setcode do
   host = Facter.value(:hostname)
   domain = Facter.value(:domain)
   if File.exists?('/etc/ipa/primary')
     if host and domain
       fqdn = [host, domain].join(".")
     end
   servers = Facter::Util::Resolution.exec("/sbin/runuser -l admin -c '/usr/sbin/ipa-replica-manage list' 2>/dev/null | /bin/egrep -v '#{fqdn}|winsync' | /bin/cut -d: -f1")
   combinations = servers.scan(/[\w.-]+/).combination(2).to_a
   combinations.collect { |combination| combination.join(',') }.join(':')
   elsif File.exists?('/etc/ipa/primary').nil?
     'UNKNOWN'
   end
 end
end
