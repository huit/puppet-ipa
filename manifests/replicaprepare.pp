
define ipa::replicaprepare (
  $replica_fqdn = $name,
  $replica_hostname = {},
  $replica_region = {},
  $replica_ip = {},
  $dspw,
) {

  notify { "REPLICA FQDN, HOSTNAME, REGION, AND IP ARE: $replica_fqdn $replica_hostname $replica_region $replica_ip":}

  exec { "remove $replica_hostname":
    command => "ipa-replica-manage del ${replica_fqdn} --password ${adminpw} --force ; echo true",
    before  => File_line["add $replica_hostname to hosts"]
  }

  Cron['k5start_root'] -> File_line["add $replica_hostname to hosts"] ~> Exec["replicaprepare-${replica_fqdn}"] ~> Exec["replica-info-upload-${replica_fqdn}"] # ~> Ipa::Hostdelete[$replica_fqdn]

  file_line { "add $replica_hostname to hosts":
    ensure  => present,
    line    => "$replica_ip $replica_fqdn $replica_hostname",
    path    => '/etc/hosts'
  }

#  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}",'--no-wait-for-dns')
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${replica_fqdn}":
    command => "${replicapreparecmd} ${replica_fqdn}",
    unless  => "${replicamanagecmd} list | /bin/grep ${replica_fqdn} >/dev/null 2>&1",
    timeout => '0',
  }

  exec { "replica-info-upload-${replica_fqdn}":
    command     => "/bin/aws s3 cp /var/lib/ipa/replica-info-${replica_fqdn}.gpg s3://${::environment}-${replica_region}-s3-credentials/ipa_gpg/",
  }

#  ipa::hostdelete { $replica_fqdn:}
}
