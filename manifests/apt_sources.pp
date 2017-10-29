class omegaup::apt_sources (
  $use_newrelic = false,
) {
  # Stages
  stage { 'init':
    before => Stage['main'],
  }

  # Packages
  class { 'apt':
    update => {
      frequency => 'daily',
    },
    stage  => init,
  }

  include apt

  Apt::Source <| |> ~> Class['apt::update']

  class { '::omegaup::apt_sources::internal':
    stage        => init,
    use_newrelic => use_newrelic,
  }
}

# vim:expandtab ts=2 sw=2
