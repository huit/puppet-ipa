# Definition: ipa::serverinstall
#
# Installs an IPA server
define ipa::serverinstall (
  $host          = $name,
  $master_region,
  $replica1_region,
  $replica2_region,
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
    master_region   => $master_region,
    replica1_region => $replica1_region,
    replica2_region => $replica2_region,
    adminpw         => $adminpw,
    dspw            => $dspw,
    require         => Anchor['ipa::serverinstall::end']
  }
}
