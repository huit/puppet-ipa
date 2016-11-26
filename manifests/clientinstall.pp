# Definition: ipa::clientinstall
#
# Installs an IPA client
define ipa::clientinstall (
  $host         = $name,
  $domain       = {},
  $realm        = $profile::freeipa::realm,
  $otp          = {},
  $mkhomedir    = {},
  $ntp          = {},
  $fixedprimary = false
) {

  $masterfqdn = "freeipa-master.${domain}"

#  Exec["client-install-${host}"] 
# ~> Ipa::Flushcache["client-${host}"]

  $principal = upcase("$domain")

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

  $clientinstallcmd = shellquote('/usr/sbin/ipa-client-install',"--server=${masterfqdn}","--hostname=${host}","--domain=${domain}","--realm=${realm}","--principal=admin@${principal}","--password=${otp}",$mkhomediropt,$ntpopt,$fixedprimaryopt,'--unattended')
  $dc = prefix([regsubst($domain,'(\.)',',dc=','G')],'dc=')
  $searchostldapcmd = shellquote('/usr/bin/k5start','-u',"host/${host}",'-f','/etc/krb5.keytab','--','/usr/bin/ldapsearch','-Y','GSSAPI','-H',"ldap://${masterfqdn}",'-b',$dc,"fqdn=${host}")

  exec { "client-install-${host}":
    command   => "/bin/echo | ${clientinstallcmd}",
    unless    => "${searchostldapcmd} | /bin/grep ^krbLastPwdChange",
    timeout   => '0',
    tries     => '60',
    try_sleep => '90',
    returns   => ['0','1'],
    logoutput => 'on_failure'
  }

#  ipa::flushcache { "client-${host}":
 # }
   
  if "$mkhomedir" == 'true' {
    exec { "allow user logins":
      command => "authconfig --update --enablemkhomedir"
    }
  } ->
  notify { "MEOWWWWWWWWWWWWWWWWW $clientinstallcmd": }

}
