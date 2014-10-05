# Definition: ipa::clientinstall
#
# Installs an IPA client
define ipa::clientinstall (
  $host         = $name,
  $masterfqdn   = {},
  $domain       = {},
  $realm        = {},
  $adminpw      = {},
  $otp          = {},
  $mkhomedir    = {},
  $ntp          = {},
  $fixedprimary = false
) {

  Exec["client-install-${host}"] ~> Ipa::Flushcache["client-${host}"]

  $mkhomediropt = $mkhomedir ? {
    true    => '--mkhomedir',
    default => ''
  }

  $ntpopt = $ntp ? {
    true    => '',
    default => '--no-ntp'
  }

  $fixedprimaryopt = $fixedprimary ? {
    true    => '--fixed-primary',
    default => ''
  }

  $clientinstallcmd = shellquote('/usr/sbin/ipa-client-install',"--server=${masterfqdn}","--hostname=${host}","--domain=${domain}","--realm=${realm}","--password=${otp}",$mkhomediropt,$ntpopt,$fixedprimaryopt,'--unattended')
  $dc = prefix([regsubst($domain,'(\.)',',dc=','G')],'dc=')

  exec { "client-install-${host}":
    command   => "/bin/echo | ${clientinstallcmd}",
    unless    => shellquote('/bin/bash','-c',"LDAPTLS_REQCERT=never /usr/bin/ldapsearch -LLL -x -H ldaps://${masterfqdn} -D uid=admin,cn=users,cn=accounts,${dc} -b ${dc} -w ${adminpw} fqdn=${host} | /bin/grep ^krbLastPwdChange"),
    timeout   => '0',
    tries     => '60',
    try_sleep => '90',
    returns   => ['0','1'],
    logoutput => 'on_failure'
  }

  ipa::flushcache { "client-${host}":
  }
}
