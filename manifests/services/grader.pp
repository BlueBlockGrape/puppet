# The omegaUp grader service.
class omegaup::services::grader (
  $user = undef,
  $hostname = 'localhost',
  $embedded_runner = true,
  $broadcaster_host = 'https://localhost:32672',
  $frontend_host = 'http://localhost',
  $keystore_password = 'omegaup',
  $local_database = false,
  $mysql_db = 'omegaup',
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $root = '/opt/omegaup',
  $services_ensure = running,
) {
  include omegaup::directories
  include omegaup::libinteractive
  include omegaup::scripts
  include omegaup::users

  # Configuration
  file { '/etc/omegaup/grader/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0600',
    content => template('omegaup/grader/config.json.erb'),
    require => File['/etc/omegaup/grader'],
  }

  # Runtime files
  file { ['/var/log/omegaup/service.log', '/var/log/omegaup/tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { ['/var/lib/omegaup/input', '/var/lib/omegaup/cache',
          '/var/lib/omegaup/grade', '/var/lib/omegaup/ephemeral']:
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }
  exec { 'submissions-directory':
    creates => '/var/lib/omegaup/submissions',
    command => '/usr/bin/mkhexdirs /var/lib/omegaup/submissions www-data omegaup 775',
    require => [File['/var/lib/omegaup'], File['/usr/bin/mkhexdirs'],
                User['www-data']],
  }
  exec { 'submissions-directory-amend':
    command => '/bin/chown omegaup:omegaup /var/lib/omegaup/submissions/* && /bin/chmod 755 /var/lib/omegaup/submissions/*',
    unless  => '/usr/bin/test "$(/usr/bin/stat -c "%U:%G %a" /var/lib/omegaup/submissions/00)" = "omegaup:omegaup 755"',
    require => [Exec['submissions-directory'], User['omegaup']],
  }

  # Service
  file { '/etc/systemd/system/omegaup-grader.service':
    ensure  => 'file',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/grader/omegaup-grader.service.erb'),
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-grader':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/etc/omegaup/grader/config.json',
        '/etc/systemd/system/omegaup-grader.service',
        '/usr/bin/omegaup-grader',
      ],
      Exec['omegaup-backend'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-grader.service',
        '/var/lib/omegaup/input', '/var/lib/omegaup/cache',
        '/var/lib/omegaup/grade', '/var/log/omegaup/service.log',
        '/usr/bin/omegaup-grader',
        '/var/log/omegaup/tracing.json',
        '/etc/omegaup/grader/config.json',
      ],
      Remote_File['/usr/share/java/libinteractive.jar'],
    ],
  }
}

# vim:expandtab ts=2 sw=2
