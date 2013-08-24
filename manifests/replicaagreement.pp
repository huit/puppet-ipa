define ipa::replicaagreement (
  $host        = $name,
  $replicapair = []
) {

  $pair = split($replicapair, '[:]')
  $from = $pair[0]
  $to   = $pair[1]

  exec { "connectreplicas-${host}":
    command     => "/sbin/runuser -l admin -c \'/usr/sbin/ipa-replica-manage connect --cacert=/etc/ipa/ca.crt ${from} ${to}\'",
    unless      => "/sbin/runuser -l admin -c \'/usr/sbin/ipa-replica-manage list ${from} | /bin/grep ${to} >/dev/null 2>&1\'",
    logoutput   => "on_failure"
  }
}
