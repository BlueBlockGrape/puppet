class omegaup::developer_environment (
  $root,
  $user,
  $mysql_host,
  $mysql_user,
  $mysql_db,
  $mysql_password,
) {
  # Packages
  package { [ 'vim', 'openssh-client', 'gcc', 'g++',
              'clang-format-3.7', 'python-pip', 'python3-six', 'python-six',
              'silversearcher-ag', 'libgconf-2-4',
              'ca-certificates', 'meld', 'vim-gtk', 'yarn', 'nodejs']:
    ensure  => present,
  }
  package { ['python3-pep8', 'pylint3']:
    ensure => absent,
  }
  remote_file { '/usr/bin/phpcbf':
    url      => 'https://github.com/squizlabs/PHP_CodeSniffer/releases/download/3.4.0/phpcbf.phar',
    sha1hash => 'f8030b99bb21805b573c9a76d1affe8d00f28586',
    mode     => '755',
    owner    => 'root',
    group    => 'root',
  }
  Anchor['php::begin'] -> class { '::php::phpunit':
    source      => 'https://phar.phpunit.de/phpunit-5.3.4.phar',
    auto_update => false,
    path        => '/usr/bin/phpunit',
  } -> Anchor['php::end']
  exec { 'closure-linter':
    command => '/usr/bin/pip install https://github.com/google/closure-linter/zipball/master',
    creates => '/usr/local/bin/fixjsstyle',
  }
  exec { 'pylint':
    command  => '/usr/bin/pip3 install pylint==2.2.2',
    require  => Package['python3-pip'],
    unless   => [
      '/bin/bash -c \'/usr/bin/python3 -m pip list 2>/dev/null | grep -E "^pylint\s+\(?2.2.2\)?\$" > /dev/null\'',
    ],
  }
  exec { 'pycodestyle':
    command  => '/usr/bin/pip3 install pycodestyle==2.5.0',
    require  => Package['python3-pip'],
    unless   => [
      '/bin/bash -c \'/usr/bin/python3 -m pip list 2>/dev/null | grep -E "^pycodestyle\s+\(?2.5.0\)?\$" > /dev/null\'',
    ],
  }
  exec { 'yapf':
    command  => '/usr/bin/pip3 install yapf==0.25.0',
    require  => Package['python3-pip'],
    unless   => [
      '/bin/bash -c \'/usr/bin/python3 -m pip list 2>/dev/null | grep -E "^yapf\s+\(?0.25.0\)?\$" > /dev/null\'',
    ],
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
      'OMEGAUP_ENVIRONMENT' => 'development',
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
    url      => 'https://chromedriver.storage.googleapis.com/2.43/chromedriver_linux64.zip',
    sha1hash => '63bce01580d6bc488aa185d572500f342f10eeef',
    mode     => '644',
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
  package { ['google-chrome-stable', 'python3-pytest', 'python3-flaky',
             'firefox']:
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
    mode     => '644',
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

  # phpminiadmin
  file { "${root}/frontend/www/phpminiadmin":
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    require => Github[$root],
  }
  remote_file { "${root}/frontend/www/phpminiadmin/index.php":
    url      => 'https://raw.githubusercontent.com/osalabs/phpminiadmin/f0a35497e8a29dea595a13987d82eabc1e830d0b/phpminiadmin.php',
    sha1hash => '22d69c7336977cf7b20413d373ede57507c0caaa',
    mode     => '644',
    owner    => $user,
    group    => $user,
    require  => File["${root}/frontend/www/phpminiadmin"],
  }
  file { "${root}/frontend/www/phpminiadmin/phpminiconfig.php":
    content => template('omegaup/developer_environment/phpminiconfig.php.erb'),
    mode    => '644',
    owner   => $user,
    group   => $user,
    require => File["${root}/frontend/www/phpminiadmin"],
  }
}

# vim:expandtab ts=2 sw=2
