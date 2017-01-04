# Definition: ipa::serverinstall
#
# Installs an IPA server
define ipa::serverinstall (
  $host            = $name,
  $realm           = hiera('profile::freeipa::realm'),
  $domain          = hiera('profile::freeipa::domain'),
  $adminpw         = hiera('profile::freeipa::adminpw'),
  $dspw            = hiera('profile::freeipa::dspw'),
  $dnsopt          = {},
  $forwarderopts   = {},
  $ntpopt          = {},
  $extcaopt        = {},
  $idstart         = {},
) {

  $idstartopt = "--idstart=${idstart}"

  anchor { 'ipa::serverinstall::start': }

  file { '/var/lib/ipa/backup/latest':
    ensure  =>  directory,
    mode    =>  0600,
    before  =>  Exec["serverinstall-${host}"]
  }

  if ($::restore == "true") {
    $install_command = shellquote('/usr/sbin/ipa-restore',"/var/lib/ipa/backup/${::restore_dir}",'--unattended','--password',"${adminpw}")
    exec { 'download s3 backup':
      command => "aws s3 cp s3://infrastructure-${::environment}-s3-credentials/ipa_backups/${::restore_dir}/ /var/lib/ipa/backup/latest/ --recursive",
      before  => Exec["serverinstall-${host}"],
      require => File['/var/lib/ipa/backup/latest']
    }
    exec { 'download s3 host keys':
      command => "aws s3 cp s3://infrastructure-${::environment}-s3-credentials/master_host_keys/ /etc/ssh/ --recursive",
      before  => Exec["serverinstall-${host}"],
      require => File['/var/lib/ipa/backup/latest']
    }
    exec { 'download custodia s3':
      command => "aws s3 cp s3://infrastructure-${::environment}-s3-credentials/custodia/ /etc/ipa/custodia/ --recursive",
      before  => Exec["serverinstall-${host}"],
      require => File['/var/lib/ipa/backup/latest']
    }
    exec { 'download dogtag s3':
      command => "aws s3 cp s3://infrastructure-${::environment}-s3-credentials/.dogtag/ /root/.dogtag/ --recursive",
      before  => Exec["serverinstall-${host}"],
      require => File['/var/lib/ipa/backup/latest']
    }
    exec { 'set key permissions':
      command  =>  'chown root:ssh_keys /etc/ssh/ssh_host_*key && chmod 644 /etc/ssh/ssh_host*.pub',
      before  => Exec["serverinstall-${host}"],
      require => Exec['download s3 host keys']
    }
  } else {
      $install_command = shellquote('/usr/sbin/ipa-server-install',"--hostname=${host}","--realm=${realm}","--domain=${domain}","--admin-password=${adminpw}","--ds-password=${dspw}","${dnsopt}","${forwarderopts}",'--no-ntp',"${extcaopt}","${idstartopt}",'--unattended',"--ip-address=${::ipaddress}")
  }

  notify { "Installing IPA Master. Restore option is set to ${restore}, restore directory is set to ${::restore_dir}":
    before => Exec["serverinstall-${host}"]
  }

  exec { "serverinstall-${host}":
    command   => "${install_command}",
    timeout   => '0',
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
#    notify    => Ipa::Flushcache["server-${host}"]
  }

#  ipa::flushcache { "server-${host}":
#    notify  => Ipa::Adminconfig[$host],
#    require => Anchor['ipa::serverinstall::start']
#  }

#  ipa::adminconfig { $host:
#    realm   => $realm,
#    idstart => $idstart,
#    require => Anchor['ipa::serverinstall::start']
#  }

  anchor { 'ipa::serverinstall::end':
    require => Exec["serverinstall-${host}"]
  }

  exec { 'authorize-home-dirs':
    command => 'authconfig --enablemkhomedir --update',
    require => Anchor['ipa::serverinstall::end']
  }

}
