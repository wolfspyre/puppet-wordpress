# == Class: wordpress::standalone::service
#  wrapper class
class wordpress::standalone::service {
  Anchor['wordpress::config::end'] -> Class['wordpress::standalone::service']
  #make our parameters local scope
  $apache_pkg    = $wordpress::standalone::package::apache_pkg
  $app_archive   = $wordpress::standalone::app_archive
  $app_hash      = $wordpress::standalone::app_hash
  $create_group  = $wordpress::standalone::create_group
  $create_user   = $wordpress::standalone::create_user
  $docroot       = $wordpress::standalone::docroot
  $db_host       = $wordpress::standalone::db_host
  $db_name       = $wordpress::standalone::db_name
  $db_password   = $wordpress::standalone::db_password
  $db_user       = $wordpress::standalone::db_user
  $mysql_version = $wordpress::standalone::mysql_version
  $parent        = $wordpress::standalone::parent
  $app_full_path = $wordpress::standalone::app_full_path
  Service{} -> Anchor['wordpress::service::end']
  # end of variables
  case $::osfamily {
    RedHat: {
      $apache_svc = 'httpd'
      case $mysql_version {
        5.0: {
          $mysql_svc = 'mysqld'
        }
        5.1: {
          $mysql_svc = 'mysqld'
        }
        5.5: {
          $mysql_svc = 'mysql'
        }
        default: {
          fail "unsupported MySQL Version requested ${mysql_version}. Supported options are 5.0, 5.1 and 5.5"
        }
      }#end mysql_version case
    }
    Debian: {
      $apache_svc = 'httpd'
      $mysql_svc =  'mysql'
    }
    default: {
      fail "Unsupported osfamily ${::osfamily} on ${::fqdn}"
    }
  }#end OSFamily case

  #variables are set. Ensure the services are running.
  service { $mysql_svc:
    ensure  => 'running',
    require => Package[$wordpress::standalone::package::mysql_pkgs]
  }
  service { $apache_svc:
    ensure    => 'running',
    subscribe => File['wordpress_vhost'],
    require   => Package[$wordpress::standalone::package::apache_pkg]
  }
  #create the database
  exec {'create_schema':
    path     => '/usr/bin:/usr/sbin:/bin',
    command  => "mysql -uroot < ${app_full_path}/setup_files/create_wordpress_db.sql",
    unless   => "mysql -uroot -e \"use ${db_name}\"",
    notify   => Exec['grant_privileges'],
    require  => [ Service[ $mysql_svc ], File['wordpress_sql_script'],]
  }
  exec {'grant_privileges':
      path        => '/usr/bin:/usr/sbin:/bin',
      command     => "mysql -uroot -e \"grant all privileges on\
                      ${db_name}.* to\
                      '${db_user}'@'localhost'\
                      identified by '${db_password}'\"",
      unless      => "mysql -u${db_user}\
                      -p${db_password}\
                      -D${db_name} -hlocalhost",
      refreshonly => true;
  }

}#end class
