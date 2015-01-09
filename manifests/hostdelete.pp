define ipa::hostdelete (
  $host = $name
) {

  exec { "hostdelete-${host}":
    command     => "kinit -kt /home/admin/admin.keytab admin && /sbin/runuser -l admin -c \'/usr/bin/ipa host-del ${host}\'",
    refreshonly => true,
    onlyif      => "kinit -kt /home/admin/admin.keytab admin && /sbin/runuser -l admin -c \'/usr/bin/ipa host-show ${host} >/dev/null 2>&1\'"
  }
}
