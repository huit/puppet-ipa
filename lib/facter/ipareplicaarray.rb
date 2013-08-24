Facter.add(:ipareplicaarray) do
  setcode do
    begin
      host = Facter.value(:hostname)
      domain = Facter.value(:domain)
      if host and domain
        fqdn = [host, domain].join(".")
      else
        nil
      end
      replicas = `/sbin/runuser -l admin -c '/usr/sbin/ipa-replica-manage list' 2>/dev/null | /bin/grep -v #{fqdn} | /bin/cut -d: -f1 | /usr/bin/tr -t '\n' ','`
      replicas.chop.scan(/[\w.-]+/).map(&:to_s).to_a.combination(2).to_a.inspect
    end
  end
end
