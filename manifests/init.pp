class apache(
  $config = '',
  $worker = 'mpm'
) {
  package { 'apache2':
    ensure => 'present',
  }

  package { 'apache2-worker':
    ensure => 'present',
    name   => 'apache2-mpm-worker',
  }

  package { 'apache2-doc':
    ensure => 'absent',
  }

  service { 'apache2':
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
    require    => Package['apache2-worker'],
  }

  exec { 'reload-apache2':
    command     => '/etc/init.d/apache2 reload',
    refreshonly => true,
    require     => Package['apache2'],
  }

  exec { 'force-reload-apache2':
    command     => '/etc/init.d/apache2 force-reload',
    refreshonly => true,
    require     => Package['apache2'],
  }

  # remove the default site
  file { '/etc/apache2/sites-enabled/000-default':
    ensure  => absent,
    notify  => Exec['reload-apache2'],
    require => Package['apache2']
  }

  apache::site { ['default', 'default-ssl']: ensure => 'absent', }

  # the aliases module sets up /icons/ as a global alias. this is pretty terrible
  apache::module { 'alias': config_content => '', }

  # apache-doc conf.d ends up leaving directory listings enabled
  apache::config { 'apache-doc': ensure => 'absent', }
}
