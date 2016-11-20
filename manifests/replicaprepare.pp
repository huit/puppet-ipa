define ipa::replicaprepare (
  $adminpw,
  $host = $title,
  $dspw,
) {

$data = {
  ipa_hosts => {
    'freeipa-replica-1.infra.bitbrew.com' => {
      host_ip => '52.209.186.125',
      host_region => 'eu-west-1',
    },
    'freeipa-replica-2.infra.bitbrew.com' => {
      host_ip => '52.212.242.94',
      host_region => 'us-east-1',
    },
  }
}

  $host_ip = $data['ipa_hosts'][$host]['host_ip']
  $host_region = $data['ipa_hosts'][$host]['region']

  notify { "replica1 host set to ${host}": }

  Cron['k5start_root'] -> Exec["replicaprepare-${host}"] ~> Exec["replica-info-upload-${host}"] ~> Ipa::Hostdelete[$host]

  $replica1_file = "/var/lib/ipa/replica-info-${host}.gpg"

  realize Cron['k5start_root']

  $replicapreparecmd = shellquote('/usr/sbin/ipa-replica-prepare',"--password=${dspw}",'--no-wait-for-dns')
  $replicamanagecmd = shellquote('/usr/sbin/ipa-replica-manage',"--password=${dspw}")

  exec { "replicaprepare-${host}":
    command => "${replicapreparecmd} ${host}",
    unless  => "${replicamanagecmd} list | /bin/grep ${host} >/dev/null 2>&1",
    timeout => '0'
  }

  exec { "replica-info-upload-${host}":
    command     => "/bin/aws s3 cp ${replica1_file} s3://${::environment}-hub-${host_region}-s3-credentials/ipa_gpg/"
    }
  ipa::hostdelete { $host:
  }
}
