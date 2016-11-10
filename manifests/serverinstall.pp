# Definition: ipa::serverinstall
#
# Installs an IPA server
define ipa::serverinstall (
  $host          = $name,
  $realm         = {},
  $domain        = {},
  $adminpw       = {},
  $dspw          = {},
  $dnsopt        = {},
  $forwarderopts = {},
  $ntpopt        = {},
  $extcaopt      = {},
  $idstart       = {},
) {

  $idstartopt = "--idstart=${idstart}"

  anchor { 'ipa::serverinstall::start': }

  file { '/var/lib/ipa/backup/latest':
    ensure  =>  directory,
    mode    =>  644,
    before  =>  Exec["serverinstall-${host}"]
  }



  if ($::restore == "true") {
    $install_command = shellquote('/usr/sbin/ipa-restore',"/var/lib/ipa/backup/${restore_dir}",'--unattended','--password',"${adminpw}")
    exec { 'download s3 backup':
      command => "aws s3 cp s3://management-hub-${region}-s3-credentials/ipa_backups/${restore_dir}/ /var/lib/ipa/backup/latest/ --recursive",
      before  => Exec["serverinstall-${host}"],
      require => File['/var/lib/ipa/backup/latest']
    }
  } else {
      $install_command = shellquote('/usr/sbin/ipa-server-install',"--hostname=${host}","--realm=${realm}","--domain=${domain}","--admin-password=${adminpw}","--ds-password=${dspw}","${dnsopt}","${forwarderopts}","${ntpopt}","${extcaopt}","${idstartopt}",'--unattended')
  }

  notify { "## Installing IPA Master. ## Command: ${install_command} ## restore=${restore} restore_dir=${restore_dir}":
    before => Exec["serverinstall-${host}"]
  }

  exec { "serverinstall-${host}":
    command   => "${install_command}",
    timeout   => '0',
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
    notify    => Ipa::Flushcache["server-${host}"]
  }

  ipa::flushcache { "server-${host}":
    notify  => Ipa::Adminconfig[$host],
    require => Anchor['ipa::serverinstall::start']
  }

  ipa::adminconfig { $host:
    realm   => $realm,
    idstart => $idstart,
    require => Anchor['ipa::serverinstall::start']
  }

  anchor { 'ipa::serverinstall::end':
    require => [Ipa::Flushcache["server-${host}"], Ipa::Adminconfig[$host]]
  }

  ::ipa::replicaprepare { 'replicaprepare':
    adminpw         => $adminpw,
    dspw            => $dspw,
    require         => Anchor['ipa::serverinstall::end']
  }

  exec { 'authorize-home-dirs':
    command => 'authconfig --enablemkhomedir --update',
    require => Anchor['ipa::serverinstall::end']
  }

}
