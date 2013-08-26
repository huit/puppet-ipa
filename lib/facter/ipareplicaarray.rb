Facter.add(:ipareplicaarray) do
 setcode do
   host = Facter.value(:hostname)
   domain = Facter.value(:domain)
   ipaadminhomedir = Facter.value(:ipaadminhomedir)
   if File.directory?(ipaadminhomedir)
     if host and domain
       fqdn = [host, domain].join(".")
     end
   elsif File.directory?(ipaadminhomedir).nil?
     'UNKNOWN'
   end
   servers = Facter::Util::Resolution.exec("/sbin/runuser -l admin -c '/usr/sbin/ipa-replica-manage list' 2>/dev/null | /bin/grep -v #{fqdn} | /bin/cut -d: -f1")
   combinations = servers.scan(/[\w.-]+/).combination(2).to_a
   combinations.collect { |combination| combination.join(',') }.join(':')
 end
end
