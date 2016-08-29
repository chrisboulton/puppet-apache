define apache::site(
  $ensure = 'present',
  $source = '',
  $content = ''
) {
  validate_string($source, $content)
  if ($ensure != 'present' and $ensure != 'absent') {
    fail("Apache::Site[$name] ensure should be one of present/absent")
  }

  if ($content and $source) {
    fail("Apache::Site[$name] cannot specify both source and content")
  }
  case $lsbdistcodename {
    'jessie': {
      $sites_enabled_path   = "/etc/apache2/sites-enabled/${name}.conf"
      $sites_available_path = "/etc/apache2/sites-available/${name}.conf"
    }
    default: {
      $sites_enabled_path   = "/etc/apache2/sites-enabled/${name}"
      $sites_available_path = "/etc/apache2/sites-available/${name}"
    }
  }

  File {
    notify => Service['apache2'],
    owner  => 'root',
    group  => 'root',
  }

  if ($content) {
    file { $sites_available_path:
      content => $content,
      ensure  => $ensure,
    }
  }
  elsif ($source) {
    # if ensure is false, puppet still tries to find the file referenced in source. if
    # we have also deleted the file, puppet will error even though we're trying to remove.
    if ($ensure == 'absent') {
      file { $sites_available_path:
        ensure => $ensure,
      }
    } else {
      file { $sites_available_path:
        source => $source,
        ensure => $ensure,
      }
    }
  }
  else {
    file { $sites_available_path: }
  }

  if ($ensure == 'present') {
    exec { "/usr/sbin/a2ensite ${name}":
      creates => $sites_enabled_path,
      notify  => Exec['reload-apache2'],
      require => File[$sites_available_path],
    }
  }
  else {
    exec { "/usr/sbin/a2dissite ${name}":
      onlyif  => "/usr/bin/stat ${sites_enabled_path}",
      notify  => Exec['reload-apache2'],
      require => File[$sites_available_path],
    }
  }
}
