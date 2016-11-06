define ipa::replicaprepare (
  $replica1_region = $profile::freeipa::replica1_region,
  $replica2_region = $profile::freeipa::replica1_region,
  $adminpw,
# $host = $name,
  $host = "freeipa-${profile::freeipa::replica1_region}-management.${::public_dns}",
  $dspw
) {

  notify { "replica1_region is ${replica1_region}": }

  Cron['k5start_root'] -> Exec["replicaprepare-${host}"] ~> Exec["replica-info-upload-${host}"] ~> Ipa::Hostdelete[$host]

  $file = "/var/lib/ipa/replica-info-${host}.gpg"

  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}")
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${host}":
    command => "${replicapreparecmd} ${host}",
    unless  => "${replicamanagecmd} list | /bin/grep ${host} >/dev/null 2>&1",
    timeout => '0'
  }

  exec { "replica-info-upload-${host}":
    command     => "/bin/aws s3 cp /var/lib/ipa/replica-info-${host}.gpg s3://management-hub-${replica1_region}-s3-credentials/ipa_gpg/"
    }
  ipa::hostdelete { $host:
  }
}
