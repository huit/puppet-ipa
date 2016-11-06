define ipa::replicaprepare (
  $replica1_region = $profile::freeipa::replica1_region,
  $replica2_region = $profile::freeipa::replica2_region,
  $adminpw,
  $replica1_host = "freeipa-${profile::freeipa::replica1_region}-management.${::public_dns}",
  $replica2_host = "freeipa-${profile::freeipa::replica2_region}-management.${::public_dns}",
# $host = $name,
#  $host = "freeipa-${profile::freeipa::replica1_region}-management.${::public_dns}",
  $dspw
) {

  notify { "replica1_region is ${replica1_region}": }

  Cron['k5start_root'] -> Exec["replicaprepare-${replica1_host}"] ~> Exec["replica-info-upload-${replica1_host}"] ~> Ipa::Hostdelete[$replica1_host]

  $file = "/var/lib/ipa/replica-info-${replica1_host}.gpg"

  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}")
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${replica1_host}":
    command => "${replicapreparecmd} ${replica1_host}",
    unless  => "${replicamanagecmd} list | /bin/grep ${replica1_host} >/dev/null 2>&1",
    timeout => '0'
  }

  exec { "replica-info-upload-${replica1_host}":
    command     => "/bin/aws s3 cp /var/lib/ipa/replica-info-${replica1_host}.gpg s3://management-hub-${replica1_region}-s3-credentials/ipa_gpg/"
    }
  ipa::hostdelete { $replica1_host:
  }




  notify { "replica region is ${replica2_region}": }

  Cron['k5start_root'] -> Exec["replicaprepare-${replica2_host}"] ~> Exec["replica-info-upload-${replica2_host}"] ~> Ipa::Hostdelete[$replica2_host]

  $file = "/var/lib/ipa/replica-info-${replica2_host}.gpg"

  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}")
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${replica2_host}":
    command => "${replicapreparecmd} ${replica2_host}",
    unless  => "${replicamanagecmd} list | /bin/grep ${replica2_host} >/dev/null 2>&1",
    timeout => '0'
  }

  exec { "replica-info-upload-${replica2_host}":
    command     => "/bin/aws s3 cp /var/lib/ipa/replica-info-${replica2_host}.gpg s3://management-hub-${replica1_region}-s3-credentials/ipa_gpg/"
    }
  ipa::hostdelete { $replica2_host:
  }






}
