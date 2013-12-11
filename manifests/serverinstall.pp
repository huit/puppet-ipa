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
    notify => Ipa::Puppetrunin1min["serverinstall"],
  }

  ipa::puppetrunin1min { "serverinstall":
  }

  if $::ipa_adminhomedir and is_numeric($::ipa_adminuidnumber) {
    k5login { "${::ipa_adminhomedir}/.k5login":
      principals => $ipa::master::principals,
      notify     => File["${::ipa_adminhomedir}/.k5login"],
      require    => File["${::ipa_adminhomedir}"]
    }

    exec { "admin_keytab":
      command => shellquote('/usr/sbin/kadmin.local','-q','"ktadd -norandkey -k admin.keytab admin"',';','/usr/bin/k5start','-f',"${::ipa_adminhomedir}/admin.keytab",'-U','-o','admin','-k',"/tmp/krb5cc_${::ipa_adminuidnumber}",'>','/dev/null','2>&1'),
      cwd     => "${::ipa_adminhomedir}",
      unless  => shellquote('/usr/bin/kvno','-c',"/tmp/krb5cc_${::ipa_adminuidnumber}",'-k',"${::ipa_adminhomedir}/admin.keytab","admin@${realm}"),
      notify  => File["${::ipa_adminhomedir}/admin.keytab"],
      require => Cron["k5start_admin"]
    }

    cron { "k5start_admin":
      command => shellquote("/usr/bin/k5start -f ${::ipa_adminhomedir}/admin.keytab -U -o admin -k /tmp/krb5cc_${::ipa_adminuidnumber} > /dev/null 2>&1"),
      user    => 'root',
      minute  => "*/1",
      require => [Package["kstart"], K5login["${::ipa_adminhomedir}/.k5login"], File["$::ipa_adminhomedir"]]
    }

    file { "$::ipa_adminhomedir":
      ensure  => directory,
      mode    => '700',
      owner   => $::ipa_adminuidnumber,
      group   => $::ipa_adminuidnumber,
      recurse => true,
      notify  => Exec["admin_keytab"],
      require => Exec["serverinstall-${host}"]
    }

    file { "${::ipa_adminhomedir}/.k5login":
      owner   => $::ipa_adminuidnumber,
      group   => $::ipa_adminuidnumber,
      require => File[$::ipa_adminhomedir]
    }

    file { "${::ipa_adminhomedir}/admin.keytab":
      owner   => $::ipa_adminuidnumber,
      group   => $::ipa_adminuidnumber,
      mode    => '600',
      require => File[$::ipa_adminhomedir]
    }
  }
}
