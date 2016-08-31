define apache::config(
  $ensure  = 'present',
  $source  = '',
  $content = ''
) {
  validate_string($source, $content)
  if ($ensure != 'present' and $ensure != 'absent') {
    fail("Apache::Config[${name}] ensure should be one of present/absent")
  }

  if (!$content and !$source and $ensure != 'absent') {
    fail("Apache::Config[${name}] either source or content must be present")
  }
  elsif ($content and $source) {
    fail("Apache::Config[${name}] cannot specify both source and content")
  }

  File {
    notify  => Service['apache2'],
    ensure  => $ensure,
    require => Package['apache2'],
    owner   => 'root',
    group   => 'root',
  }

  case $lsbdistcodename {
    'jessie': { $conf_path = "/etc/apache2/conf-available/${name}.conf" }
    default:  { $conf_path = "/etc/apache2/conf.d/${name}.conf" }
  }

  if ($content) {
    file { $conf_path:
      content => $content,
    }
  } elsif ($ensure != 'absent') {
    file { $conf_path:
      source => $source,
    }
  } else {
    file { $conf_path:
      ensure => 'absent',
    }
  }

  case $lsbdistcodename {
    'jessie': {
      case $ensure {
        'absent': {
          $a2conf = 'a2disconf'
          Exec["/usr/sbin/${a2conf} ${name}"] {
            onlyif  => "/usr/bin/stat ${conf_path}",
          }
        }
        default:  {
          $a2conf = 'a2enconf'
          Exec["/usr/sbin/${a2conf} ${name}"] {
            creates => $conf_path
          }
        }
      }
      exec {"/usr/sbin/${a2conf} ${name}":
        notify  => Exec['reload-apache2'],
        require => File[$conf_path]
      }
      File[$conf_path] {
        notify => Exec["/usr/sbin/${a2conf} ${name}"]
      }
    }
    default: {
      File[$conf_path] {
        notify => Exec['reload-apache2']
      }
    }
  }
}
