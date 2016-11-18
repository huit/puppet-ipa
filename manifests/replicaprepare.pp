define ipa::replicaprepare (
  $replica1_region,
  $replica2_region,
  $adminpw,
# $host = $name,
#  $host = "freeipa-${profile::freeipa::replica1_region}.${::public_dns}",
  $dspw
) {


  $replica1_host = "freeipa-${replica1_region}.${::public_dns}"
  $replica2_host = "freeipa-${replica2_region}.${::public_dns}"


  notify { "replica1_region is ${replica1_region}": }

  Cron['k5start_root'] -> Exec["replicaprepare-${replica1_host}"] ~> Exec["replica-info-upload-${replica1_host}"] ~> Ipa::Hostdelete[$replica1_host]

  $replica1_file = "/var/lib/ipa/replica-info-${replica1_host}.gpg"

  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}",'--no-wait-for-dns')
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${replica1_host}":
    command => "${replicapreparecmd} ${replica1_host}",
    unless  => "${replicamanagecmd} list | /bin/grep ${replica1_host} >/dev/null 2>&1",
    timeout => '0'
  }

  exec { "replica-info-upload-${replica1_host}":
    command     => "/bin/aws s3 cp ${replica1_file} s3://${::environment}-hub-${replica1_region}-s3-credentials/ipa_gpg/"
    }
  ipa::hostdelete { $replica1_host:
  }
}


#### Replica 2
#  notify { "replica region is ${replica2_region}": }

#  Cron['k5start_root'] -> Exec["replicaprepare-${replica2_host}"] ~> Exec["replica-info-upload-${replica2_host}"] ~> Ipa::Hostdelete[$replica2_host]

#  $replica2_file = "/var/lib/ipa/replica-info-${replica2_host}.gpg"

#  realize Cron['k5start_root']

#  exec { "replicaprepare-${replica2_host}":
#    command => "${replicapreparecmd} ${replica2_host}",
#    unless  => "${replicamanagecmd} list | /bin/grep ${replica2_host} >/dev/null 2>&1",
#    timeout => '0'
#  }

#  exec { "replica-info-upload-${replica2_host}":
#    command     => "/bin/aws s3 cp ${replica2_file} s3://${::environment}-hub-${replica2_region}-s3-credentials/ipa_gpg/"
#    }
#  ipa::hostdelete { $replica2_host:
#  }
#}
