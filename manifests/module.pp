define apache::module(
  $ensure         = 'present',
  $config_source  = undef,
  $config_content = ''
) {
  validate_string($config_source, $config_content)
  if ($ensure != 'present' and $ensure != 'absent') {
    fail("Apache::Module[${name}] ensure must be one of present/absent")
  }
  if ($config_content != '' and $config_source) {
    fail("Apache::Module[${name}] cannot specify both config_source and config_content")
  }

  $mods_enabled_path   = "/etc/apache2/mods-enabled/${name}.load"
  $mods_available_path = "/etc/apache2/mods-available/${name}.load"
  $mod_config_path     = "/etc/apache2/mods-available/${name}.conf"

  File {
    notify  => Service['apache2'],
    require => Package['apache2'],
    owner   => 'root',
    group   => 'root',
  }

  if ($config_content != '') {
    file { $mod_config_path:
      ensure  => $ensure,
      content => $config_content,
    }
  }
  elsif ($config_source) {
    # if ensure is false, puppet still tries to find the file referenced in source. if
    # we have also deleted the file, puppet will error even though we're trying to remove.
    if ($ensure == 'absent') {
      file { $mod_config_path:
        ensure => $ensure,
      }
    }
    else {
      file { $mod_config_path:
        ensure => $ensure,
        source => $config_source,
      }
    }
  }
  else {
    file { $mod_config_path: }
  }
  if ($ensure == 'present') {
    exec { "/usr/sbin/a2enmod ${name}":
      unless  => "/bin/sh -c '[ -L ${mods_enabled_path} ] && [ ${mods_enabled_path} -ef ${mods_available_path} ]'",
      notify  => Exec['force-reload-apache2'],
      require => File[$mod_config_path],
    }
  }
  else {
    exec { "/usr/sbin/a2dismod ${name}":
      onlyif  => "/bin/sh -c ' [ -L ${mods_enabled_path} ] && [ ${mods_enabled_path} -ef ${mods_available_path} ]'",
      notify  => Exec['force-reload-apache2'],
      require => File[$mod_config_path],
    }
  }
}
