class { '::omegaup::apt_sources':
  development_environment => true,
}

class { '::omegaup::database':
  development_environment => true,
  root_password           => 'omegaup',
  password                => 'omegaup',
}

class { '::omegaup::certmanager': }
file { '/etc/omegaup': ensure => 'directory' }

omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  hostname => 'localhost',
  owner    => 'www-data',
  mode     => '0600',
  require  => [File['/etc/omegaup/frontend'], User['www-data']],
}
file { '/etc/omegaup/frontend':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
class { '::omegaup':
  development_environment => true,
  local_database          => true,
  mysql_password          => 'omegaup',
  user                    => 'ubuntu',
  require                 => [Class['::omegaup::database'],
                              Class['::omegaup::apt_sources']],
}

class { '::omegaup::cron':
  mysql_password => 'omegaup',
  require        => Class['::omegaup'],
}
class { '::omegaup::services':
  require        => Class['::omegaup'],
}
class { '::omegaup::services::grader':
  keystore_password => 'omegaup',
  mysql_password    => 'omegaup',
  user              => 'ubuntu',
  require           => Class['::omegaup::services'],
}
class { '::omegaup::services::runner':
  keystore_password => 'omegaup',
  require           => Class['::omegaup::services'],
}
class { '::omegaup::services::broadcaster':
  keystore_password => 'omegaup',
  require           => Class['::omegaup::services'],
}


# vim:expandtab ts=2 sw=2
