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
  $extcaopt      = {},
  $extcertpath   = {},
  $extcert       = {},
  $extcapath     = {},
  $extca         = {},
  $dirsrv_pkcs12 = {},
  $http_pkcs12   = {},
  $dirsrv_pin    = {},
  $http_pin      = {},
  $subject       = {},
  $selfsign      = {}
) {

  if $extcaopt {
    exec { "extca-serverinstall-${host}":
      command   => shellquote('/usr/sbin/ipa-server-install',"--hostname=${host}","--realm=${realm}","--domain=${domain}","--admin-password=${adminpw}","--ds-password=${dspw}",$dnsopt,$ntpopt,'--external-ca','--unattended'),
      timeout   => '0',
      creates   => '/root/ipa.csr',
      logoutput => 'on_failure'
    }

    if is_string($extcertpath) and is_string($extcapath) {
      file { $extcertpath:
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $extcert
      }

      file { $extcapath:
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $extca
      }

      if is_string($dirsrv_pkcs12) and is_string($dirsrv_pin) {
        $dirsrv_pkcs12opt = "--dirsrv_pkcs12=${dirsrv_pkcs12}"
        $dirsrv_pinopt = "--dirsrv_pin=${dirsrv_pin}"
        file { $dirsrv_pkcs12:
          ensure => 'file',
          owner  => 'root',
          group  => 'root',
          mode   => '0600',
          source => "puppet:///files/ipa/${dirsrv_pkcs12}"
        }
      } else {
        $dirsrv_pkcs12opt = ''
        $dirsrv_pinopt = ''
      }

      if is_string($http_pkcs12) {
        $http_pkcs12opt = "--http_pkcs12=${http_pkcs12}"
        $http_pinopt = "--http_pin=${http_pin}"
        file { $http_pkcs12:
          ensure => 'file',
          owner  => 'root',
          group  => 'root',
          mode   => '0600',
          source => "puppet:///files/ipa/${http_pkcs12}"
        }
      } else {
        $http_pkcs12opt = ''
        $http_pinopt = ''
      }

      if is_string($subject) {
        $subjectopt = "--subject=${subject}"
      } else {
        $subjectopt = ''
      }

      $selfsignopt = $selfsign ? {
        true    => '--selfsign',
        default => ''
      }

      if defined($extcertpath) and defined($extcapath) {
        if validate_absolute_path($extcertpath) and validate_absolute_path($extcapath) {
          exec { "complete-extca-serverinstall-${host}":
            command   => shellquote('/usr/sbin/ipa-server-install',"--external_cert_file=${extcertpath}","--external_ca_file=${extcapath}",$dirsrv_pkcs12opt,$http_pkcs12opt,$dirsrv_pinopt,$http_pinopt,$subjectopt,$selfsignopt,'--unattended'),
            timeout   => '0',
            unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
            creates   => '/etc/ipa/default.conf',
            notify    => [Class['ipa::service'],Ipa::Flushcache["server-${host}"]],
            require   => File[$extcertpath,$extcapath],
            logoutput => 'on_failure'
          }

          class { 'ipa::service':
          }
        } else {
        fail('To continue, the external CA cert will need to be a valid path.')
        }
      }
    }
  } elsif ! $extcaopt {
    exec { "serverinstall-${host}":
      command   => shellquote('/usr/sbin/ipa-server-install',"--hostname=${host}","--realm=${realm}","--domain=${domain}","--admin-password=${adminpw}","--ds-password=${dspw}",$dnsopt,$ntpopt,'--unattended'),
      timeout   => '0',
      unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
      creates   => '/etc/ipa/default.conf',
      notify    => [Class['ipa::service'],Ipa::Flushcache["server-${host}"]],
      logoutput => 'on_failure'
    }

    class { 'ipa::service':
    }
  }

  ipa::flushcache { "server-${host}":
    notify => Ipa::Adminconfig[$host],
  }

  ipa::adminconfig { $host:
    realm => $realm
  }
}
