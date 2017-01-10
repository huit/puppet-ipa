# Definition: ipa::replicainstall
# Installs an IPA replica

define ipa::replicainstall (
  $host    = $name,
  $adminpw = {},
  $dspw    = {},
  $domain,
) {

  exec { "add master host entry":
    command => "echo $(dig +short freeipa-master-${::environment}.${domain})  freeipa-master-${::environment}.${domain} freeipa-master-${::environment} >> /etc/hosts",
    before  => Exec["replicainstall-${host}"],
  }

  exec { "replicainstall-${host}":
    command     => "/usr/sbin/ipa-replica-install --hostname=${::ec2_public_hostname} --skip-conncheck --setup-ca --principal=admin --admin-password=${adminpw} --server=freeipa-master-${::environment}.infra.bitbrew.com --domain=infra.bitbrew.com --realm=INFRA.BITBREW.COM --unattended --no-host-dns --mkhomedir",
    timeout     => '0',
    onlyif      => 'test ! -f /etc/ipa/ca.crt',
  }

  exec { 'authorize-home-dirs':
    command => 'authconfig --enablemkhomedir --update',
    require => Exec["replicainstall-${host}"]
  }

}
