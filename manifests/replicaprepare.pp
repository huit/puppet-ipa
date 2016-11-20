define ipa::replicaprepare (
  $replica_name = $name,
  $dspw,
  $replica_region = {},
  $replica_ip = {},
) {

  notify { "MEOW REPLICA HOSTNAME, REGION, AND IP ARE: $replica_name $replica_region $replica_ip":}

  Cron['k5start_root'] ~> Exec["replicaprepare-${replica_name}"] ~> Exec["replica-info-upload-${replica_name}"] ~> Ipa::Hostdelete["${replica_name}"]

  $replica1_file = "/var/lib/ipa/replica-info-${replica_name}.gpg"

  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}",'--no-wait-for-dns')
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${replica_name}":
    command => "${replicapreparecmd} ${replica_name}",
    unless  => "${replicamanagecmd} list | /bin/grep ${replica_name} >/dev/null 2>&1",
    timeout => '0'
  }

  exec { "replica-info-upload-${replica_name}":
    command     => "/bin/aws s3 cp /var/lib/ipa/${replica_name} s3://${::environment}-hub-${replica_region}-s3-credentials/ipa_gpg/"
    }
  ipa::hostdelete { $replica_name:
  }
}
