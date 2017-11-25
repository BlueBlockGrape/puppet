class omegaup::developer_environment (
  $root,
  $user,
  $mysql_host,
  $mysql_user,
  $mysql_password,
) {
  # Packages
  package { [ 'vim', 'openssh-client', 'gcc', 'g++', 'python3',
              'clang-format-3.7', 'python-pip', 'python3-six', 'python-six',
              'silversearcher-ag', 'ca-certificates', 'meld', 'vim-gtk',
              'yarn', 'nodejs']:
    ensure  => present,
  }
  php::extension { 'PHP_CodeSniffer':
    ensure   => '2.9.1',
    sapi     => 'none',
    provider => 'pear',
  }
  Anchor['php::begin'] -> class { '::php::phpunit':
    source      => 'https://phar.phpunit.de/phpunit-5.3.4.phar',
    auto_update => false,
    path        => '/usr/bin/phpunit',
  } -> Anchor['php::end']
  package { 'https://github.com/google/closure-linter/zipball/master':
    ensure   => present,
    provider => 'pip',
  }

  # Test setup
  config_php { 'test settings':
    ensure   => present,
    settings => {
      'OMEGAUP_DB_USER'     => $mysql_user,
      'OMEGAUP_DB_HOST'     => $mysql_host,
      'OMEGAUP_DB_PASS'     => $mysql_password,
      'OMEGAUP_DB_NAME'     => 'omegaup-test',
      'OMEGAUP_SSLCERT_URL' => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_CACERT_URL'  => '/etc/omegaup/frontend/certificate.pem',
    },
    path     => "${root}/frontend/tests/test_config.php",
    owner    =>  $user,
    group    =>  $user,
  }
  config_php { 'developer settings':
    ensure   => present,
    settings => {
      'OMEGAUP_DEVELOPMENT_MODE' => 'true', # lint:ignore:quoted_booleans
    },
    path     => "${root}/frontend/server/config.php",
    require  => Config_php['default settings'],
  }
  config_php { 'experiments schools':
    ensure   => present,
    settings => {
      'EXPERIMENT_SCHOOLS' => 'true', # lint:ignore:quoted_booleans
    },
    path     => "${root}/frontend/server/config.php",
    require  => Config_php['default settings'],
  }
  file { "${root}/frontend/tests/controllers/omegaup.log":
    ensure => 'file',
    owner  => $user,
    group  => $user,
  }
  file { ["${root}/frontend/tests/controllers/problems",
      "${root}/frontend/tests/controllers/submissions"]:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }

  # Selenium
  remote_file { '/var/lib/omegaup/chromedriver_linux64.zip':
    url      => 'https://chromedriver.storage.googleapis.com/2.33/chromedriver_linux64.zip',
    sha1hash => '717d67ab192b1c57819528161557ce2b66b9436c',
    mode     => 644,
    owner    => 'root',
    group    => 'root',
    notify   => Exec['chromedriver'],
    require  => File['/var/lib/omegaup'],
  }
  exec { 'chromedriver':
    command     => '/usr/bin/unzip -o /var/lib/omegaup/chromedriver_linux64.zip chromedriver -d /usr/bin',
    user        => 'root',
    refreshonly => true,
  }
  package { ['google-chrome-stable', 'python3-pytest', 'firefox']:
    ensure  => present,
    require => Apt::Source['google-chrome'],
  }
  package { 'python3-selenium':
    ensure => absent,
  }
  exec { 'selenium':
    command  => '/usr/bin/pip3 install selenium',
    creates  => '/usr/local/lib/python3.5/dist-packages/selenium',
  }
  remote_file { '/var/lib/omegaup/geckodriver_linux64.tar.gz':
    url      => 'https://github.com/mozilla/geckodriver/releases/download/v0.19.1/geckodriver-v0.19.1-linux64.tar.gz',
    sha1hash => '9284c82e1a6814ea2a63841cd532d69b87eb0d6e',
    mode     => 644,
    owner    => 'root',
    group    => 'root',
    notify   => Exec['geckodriver'],
    require  => File['/var/lib/omegaup'],
  }
  exec { 'geckodriver':
    command     => '/bin/tar -xf /var/lib/omegaup/geckodriver_linux64.tar.gz --group=root --owner=root --directory=/usr/bin geckodriver',
    user        => 'root',
    refreshonly => true,
  }
}

# vim:expandtab ts=2 sw=2
