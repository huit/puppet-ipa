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
  $idstart       = {}
) {

  $idstartopt = "--idstart=${idstart}"

  anchor { 'ipa::serverinstall::start': }

  exec { "serverinstall-${host}":
    command   => "/usr/sbin/ipa-server-install --hostname=${host} --realm=${realm} --domain=${domain} --admin-password='${adminpw}' --ds-password='${dspw}' ${dnsopt} ${forwarderopts} ${ntpopt} ${extcaopt} ${idstartopt} --unattended",
    timeout   => '0',
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
    notify    => Ipa::Flushcache["server-${host}"],
    logoutput => 'on_failure'
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

  if ${::restore} == "true" {
    exec { "download backup":
      command => "aws s3 cp s3://management-hub-${region}-s3-credentials/ipa_backups/${restore_dir} /var/lib/ipa/backup/ --recursive",
      require => Anchor['ipa::serverinstall::end']
    } ->
    exec { "restoring from s3 backup":
      command   => "ipa-restore --password ${admpw} /var/lib/ipa/backup"
    } -->
    ::ipa::replicaprepare { 'replicaprepare':
      adminpw         => $adminpw,
      dspw            => $dspw,
      require         => Anchor['ipa::serverinstall::end']
    }
  }

}
