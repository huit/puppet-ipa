# Definition: ipa::replicainstall
#
# Installs an IPA replica
define ipa::replicainstall (
#  $host = "freeipa-replica-1.${::public_dns}",
  $host    = $name,
  $adminpw = {},
  $dspw    = {}
) {


  $file = "/var/lib/ipa/replica-info-${host}.gpg"

  Exec['download gpg'] ~>  Exec["replicainfocheck-${host}"] ~> Exec["clientuninstall-${host}"] ~> Exec["replicainstall-${host}"] ~> Exec["removereplicainfo-${host}"] ~> Exec['authorize-home-dirs']

  exec { "download gpg":
    command => "/bin/aws s3 cp s3://${::environment}-${::region}-s3-credentials/ipa_gpg/replica-info-${host}.gpg /var/lib/ipa/",
    before  => Exec["replicainfocheck-${host}"]
    }

  exec { "replicainfocheck-${host}":
    command   => "/usr/bin/test -e ${file}",
    tries     => '60',
    try_sleep => '60',
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    require  => Exec['download gpg']
  }

  exec { "clientuninstall-${host}":
#    command     => '/usr/sbin/ipa-client-install --uninstall --unattended',
    command     => 'echo hi',
    refreshonly => true
  }

  exec { "replicainstall-${host}":
    command     => "/usr/sbin/ipa-replica-install --admin-password=${adminpw} --password=${dspw} --skip-conncheck --unattended /var/lib/ipa/replica-info-${host}.gpg",
    timeout     => '0',
    logoutput   => 'on_failure',
    refreshonly => true
  }

  exec { "removereplicainfo-${host}":
    command     => "/bin/rm -f ${file}",
    refreshonly => true
  }
  exec { 'authorize-home-dirs':
    command => 'authconfig --enablemkhomedir --update',
    require => Exec["replicainstall-${host}"]
  }

}
