# == Class: ipa
#
# Manages IPA masters, replicas and clients.
#
# === Parameters
#
#  $master = false - Configures a server to be an IPA master LDAP/Kerberos node.
#  $replica = false - Configures a server to be an IPA replica LDAP/Kerberos node.
#  $client = false - Configures a server to be an IPA client.
#  $cleanup = false - Removes IPA specific packages.
#  $domain = undef - Defines the LDAP domain.
#  $realm = undef - Defines the Kerberos realm.
#  $adminpw = undef - Defines the IPA administrative user password.
#  $dspw = undef - Defines the IPA directory services password.
#  $otp = undef - Defines an IPA client one-time-password.
#  $dns = false - Controls the option to configure a DNS zone with the IPA master setup.
#  $loadbalance = false - Controls the option to include any additional hostnames to be used in a load balanced IPA client configuration.
#  $ipaservers = [] - Defines an array of additional hostnames to be used in a load balanced IPA client configuration.
#  $mkhomedir = false - Controls the option to create user home directories on first login.
#  $ntp = false - Controls the option to configure NTP on a client.
#  $kstart = true - Controls the installation of kstart.
#  $desc = '' - Controls the description entry of an IPA client.
#  $locality = '' - Controls the locality entry of an IPA client.
#  $location = '' - Controls the location entry of an IPA client.
#  $sssdtools = true - Controls the installation of the SSSD tools package.
#  $sssdtoolspkg = 'sssd-tools' - SSSD tools package.
#  $sssd = true - Controls the option to start the SSSD service.
#  $sudo = false - Controls the option to configure sudo in LDAP.
#  $sudopw = undef - Defines the sudo user bind password.
#  $debiansudopkg = true - Controls the installation of the Debian sudo-ldap package.
#  $automount = false - Controls the option to configure automounter maps in LDAP.
#  $autofs = false - Controls the option to start the autofs service and install the autofs package.
#  $svrpkg = 'ipa-server' - IPA server package.
#  $clntpkg = 'ipa-client' - IPA client package.
#  $ldaputils = true - Controls the instalation of the LDAP utilities package.
#  $ldaputilspkg = 'openldap-clients' - LDAP utilities package.
#
# === Variables
#
#
# === Examples
#
#
# === Authors
#
#
# === Copyright
#
#
class ipa (
  $master        = $ipa::params::master,
  $replica       = $ipa::params::replica,
  $client        = $ipa::params::client,
  $cleanup       = $ipa::params::cleanup,
  $domain        = downcase($ipa::params::domain),
  $realm         = upcase($ipa::params::realm),
  $ipaservers    = $ipa::params::ipaservers,
  $loadbalance   = $ipa::params::loadbalance,
  $adminpw       = $ipa::params::adminpw,
  $dspw          = $ipa::params::dspw,
  $otp           = $ipa::params::otp,
  $dns           = $ipa::params::dns,
  $mkhomedir     = $ipa::params::mkhomedir,
  $ntp           = $ipa::params::ntp,
  $kstart        = $ipa::params::kstart,
  $desc          = $ipa::params::desc,
  $locality      = $ipa::params::locality,
  $location      = $ipa::params::location,
  $sudo          = $ipa::params::sudo,
  $sudopw        = $ipa::params::sudopw,
  $debiansudopkg = $ipa::params::debiansudopkg,
  $automount     = $ipa::params::automount,
  $autofs        = $ipa::params::autofs,
  $svrpkg        = $ipa::params::svrpkg,
  $clntpkg       = $ipa::params::clntpkg,
  $ldaputils     = $ipa::params::ldaputils,
  $ldaputilspkg  = $ipa::params::ldaputilspkg,
  $sssdtools     = $ipa::params::sssdtools,
  $sssdtoolspkg  = $ipa::params::sssdtoolspkg,
  $sssd          = $ipa::params::sssd
) inherits ipa::params {

  @package { $ipa::svrpkg:
    ensure => installed
  }

  @package { $ipa::clntpkg:
    ensure => installed
  }

  if $ipa::ldaputils {
    @package { $ipa::ldaputilspkg:
      ensure => installed
    }
  }

  if $ipa::sssdtools {
    @package { $ipa::sssdtoolspkg:
      ensure => installed
    }
  }

  if $ipa::kstart {
    @package { "kstart":
      ensure => installed
    }
  }

  @service { "ipa":
    ensure  => 'running',
    enable  => true,
    require => Package[$ipa::svrpkg]
  }

  if $ipa::sssd and ! $ipa::cleanup {
    @service { "sssd":
      ensure => 'running',
      enable => true
    }
  }

  case $::osfamily {
    'RedHat': {
      if $ipa::mkhomedir {
        service { "oddjobd":
          ensure => 'running',
          enable => true
        }
      }
    }
  }

  if $ipa::autofs {
    @package { "autofs":
      ensure => installed
    }

    @service { "autofs":
      ensure => 'running',
      enable => true
    }
  }

  @cron { "k5start_root":
    command => "/usr/bin/k5start -f /etc/krb5.keytab -U -o root -k /tmp/krb5cc_0 > /dev/null 2>&1",
    user    => 'root',
    minute  => "*/1",
    require => Package["kstart"]
  }

  if $ipa::master and $ipa::replica {
    fail("Conflicting options selected. Cannot configure both master and replica at once.")
  }

  if ! $ipa::cleanup {
    if $ipa::master or $ipa::replica {
      validate_re("$ipa::adminpw",'^.........*$',"Parameter 'adminpw' must be at least 8 characters long")
      validate_re("$ipa::dspw",'^.........*$',"Parameter 'dspw' must be at least 8 characters long")
    }

    if ! $ipa::domain {
      fail("Required parameter 'domain' missing")
    }

    if ! $ipa::realm {
      fail("Required parameter 'realm' missing")
    }

    if ! is_domain_name($ipa::domain) {
      fail("Parameter 'domain' is not a valid domain name")
    }

    if ! is_domain_name($ipa::realm) {
      fail("Parameter 'realm' is not a valid domain name")
    }
  }

  if $ipa::cleanup {
    if $ipa::master or $ipa::replica or $ipa::client {
      fail("Conflicting options selected. Cannot cleanup during an installation.")
    } else {
      ipa::cleanup { "$fqdn":
        svrpkg  => $ipa::svrpkg,
        clntpkg => $ipa::clntpkg
      }

      if $ipa::sssd {
        realize Service["sssd"]
      }
    }
  }

  if $ipa::master {
    class { "ipa::master":
      svrpkg      => $ipa::svrpkg,
      dns         => $ipa::dns,
      domain      => $ipa::domain,
      realm       => $ipa::realm,
      adminpw     => $ipa::adminpw,
      dspw        => $ipa::dspw,
      loadbalance => $ipa::loadbalance,
      ipaservers  => $ipa::ipaservers,
      sudo        => $ipa::sudo,
      sudopw      => $ipa::sudopw,
      automount   => $ipa::automount,
      autofs      => $ipa::autofs,
      kstart      => $ipa::kstart,
      sssd        => $ipa::sssd
    }

    if ! $ipa::adminpw {
      fail("Required parameter 'adminpw' missing")
    }

    if ! $ipa::dspw {
      fail("Required parameter 'dspw' missing")
    }
  }

  if $ipa::replica {
    class { "ipa::replica":
      svrpkg      => $ipa::svrpkg,
      domain      => $ipa::domain,
      adminpw     => $ipa::adminpw,
      dspw        => $ipa::dspw,
      kstart      => $ipa::kstart,
      sssd        => $ipa::sssd
    }

    class { "ipa::client":
      clntpkg      => $ipa::clntpkg,
      ldaputils    => $ipa::ldaputils,
      ldaputilspkg => $ipa::ldaputilspkg,
      sssdtools    => $ipa::sssdtools,
      sssdtoolspkg => $ipa::sssdtoolspkg,
      sssd         => $ipa::sssd,
      loadbalance  => $ipa::loadbalance,
      ipaservers   => $ipa::ipaservers,
      mkhomedir    => $ipa::mkhomedir,
      domain       => $ipa::domain,
      realm        => $ipa::realm,
      otp          => $ipa::otp,
      sudo         => $ipa::sudo,
      automount    => $ipa::automount,
      autofs       => $ipa::autofs,
      ntp          => $ipa::ntp,
      desc         => $ipa::desc,
      locality     => $ipa::locality,
      location     => $ipa::location
    }

    if ! $ipa::adminpw {
      fail("Required parameter 'adminpw' missing")
    }

    if ! $ipa::dspw {
      fail("Required parameter 'dspw' missing")
    }

    if ! $ipa::otp {
      fail("Required parameter 'otp' missing")
    }
  }

  if $ipa::client {
    class { "ipa::client":
      clntpkg       => $ipa::clntpkg,
      ldaputils     => $ipa::ldaputils,
      ldaputilspkg  => $ipa::ldaputilspkg,
      sssdtools     => $ipa::sssdtools,
      sssdtoolspkg  => $ipa::sssdtoolspkg,
      sssd          => $ipa::sssd,
      domain        => $ipa::domain,
      realm         => $ipa::realm,
      otp           => $ipa::otp,
      sudo          => $ipa::sudo,
      debiansudopkg => $ipa::debiansudopkg,
      automount     => $ipa::automount,
      autofs        => $ipa::autofs,
      mkhomedir     => $ipa::mkhomedir,
      loadbalance   => $ipa::loadbalance,
      ipaservers    => $ipa::ipaservers,
      ntp           => $ipa::ntp,
      desc          => $ipa::desc,
      locality      => $ipa::locality,
      location      => $ipa::location
    }

    if ! $ipa::otp {
      fail("Required parameter 'otp' missing")
    }
  }
}
