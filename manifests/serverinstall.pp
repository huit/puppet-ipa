define ipa::serverinstall (
  $host    = $name,
  $realm   = {},
  $domain  = {},
  $adminpw = {},
  $dspw    = {},
  $dnsopt  = {},
  $ntpopt  = {}
) {

  exec { "serverinstall-${host}":
    command   => shellquote('/usr/sbin/ipa-server-install',"--hostname=${host}","--realm=${realm}","--domain=${domain}","--admin-password=${adminpw}","--ds-password=${dspw}","${dnsopt}","${ntpopt}",'--unattended'),
    timeout   => '0',
    unless    => "/usr/sbin/ipactl status >/dev/null 2>&1",
    creates   => "/etc/ipa/default.conf",
    notify    => Ipa::Flushcache["server-${host}"],
    logoutput => "on_failure"
  }<- notify { "Running IPA server install, please wait.": }

  ipa::flushcache { "server-${host}":
    notify => Ipa::Adminconfig[$host],
  }

  ipa::adminconfig { $host:
    realm => $realm
  }
}
