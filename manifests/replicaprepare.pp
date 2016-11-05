define ipa::replicaprepare (
  $host = freeipa-${region}-management.${::public_dns},
#  $host = $name,
  $dspw = {}
) {

  Cron['k5start_root'] -> Exec["replicaprepare-${host}"] ~> Exec["replica-info-scp-${host}"] ~> Ipa::Hostdelete[$host]

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
    command     => "/bin/aws s3 cp /var/lib/ipa/replica-info-${host}.gpg\
                    s3://management-hub-${replica1}-s3-credentials/ipa_gpg/"
    }
# shellquote('/usr/bin/scp','-q','-o','StrictHostKeyChecking=no','-o','GSSAPIAuthentication=yes','-o','ConnectTimeout=5','-o','ServerAliveInterval=2',$file,"root@${host}:${file}"),
#    refreshonly => true,
#    tries       => '60',
#    try_sleep   => '60'
#  }
  ipa::hostdelete { $host:
  }
}
