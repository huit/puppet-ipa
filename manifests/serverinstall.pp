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
  $ntpopt        = {},
  $extcaopt      = {}
) {

  $host_          = shellquote($name)
  $realm_         = shellquote(flatten([$realm]   ))
  $domain_        = shellquote(flatten([$domain  ])) 
  $adminpw_       = shellquote(flatten([$adminpw ])) 
  $dspw_          = shellquote(flatten([$dspw    ])) 
  $dnsopt_        = shellquote(flatten([$dnsopt  ])) 
  $ntpopt_        = shellquote(flatten([$ntpopt  ])) 
  $extcaopt_      = shellquote(flatten([$extcaopt])) 
 

  exec { "serverinstall-${host}":
    command   => join(['/usr/sbin/ipa-server-install',"--hostname=${host_}","--realm=${realm_}", "--domain=${domain_}","--admin-password=${adminpw_}","--ds-password=${dspw_}",$dnsopt_,$ntpopt_,$extcaopt_,'--unattended'], ' '),
    timeout   => '0',
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
    notify    => Ipa::Flushcache["server-${host}"],
    logoutput => 'on_failure'
  }

  ipa::flushcache { "server-${host}":
    notify => Ipa::Adminconfig[$host],
  }

  ipa::adminconfig { $host:
    realm => $realm
  }
}
