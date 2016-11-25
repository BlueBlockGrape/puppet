# Generates certificates needed for frontend-backend communication.
class omegaup::certmanager (
  $ssl_root = '/etc/certmanager',
  $ca_name = 'omegaUp Certificate Authority',
  $country = 'MX',
) {
  include omegaup::java

  file { '/usr/bin/certmanager':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/certmanager',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { $ssl_root:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }
  exec { 'certmanager-ca':
    command => "/usr/bin/certmanager init --root '${::omegaup::certmanager::ssl_root}' --ca-name '${ca_name}' --country '${country}'",
    creates => "${::omegaup::certmanager::ssl_root}/ca.crt",
    require => [File['/usr/bin/certmanager'], Package[$::omegaup::java::jre_package],
                File[$::omegaup::certmanager::ssl_root]],
  }
}

# vim:expandtab ts=2 sw=2
