#
class profile_redis (
  String         $bind,
  Array[Integer] $listening_ports,
  Boolean        $manage_firewall_entry,
  Boolean        $manage_prometheus_exporter,
) {
  class { 'redis':
    default_install => false,
    service_enable  => false,
    service_ensure  => 'stopped',
  }

  $listening_ports.each |$port| {
    $_port_string = sprintf('%d', $port)

    redis::instance { $_port_string:
      service_enable => true,
      service_ensure => 'running',
      port           => $port,
      bind           => $bind,
      dbfilename     => "${port}-dump.rdb",
      appendfilename => "${port}-appendonly.aof",
      appendfsync    => 'always',
      require        => Class['Redis'],
    }

    if $manage_firewall_entry {
      firewall { "0${port} accept redis":
        dport  => $port,
        action => 'accept',
      }
    }
  }

  if $manage_prometheus_exporter {
    class{ 'profile_prometheus::redis_exporter':
      ports => $listening_ports,
    }
  }
}
