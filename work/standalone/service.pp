# == Class: wordpress::standalone::service
#  wrapper class
class wordpress::standalone::service {
  Anchor['wordpress::config::end'] -> Class['wordpress::standalone::service']
  #make our parameters local scope
  $app_child_dir = $wordpress::app_dir
  $app_parent    = $wordpress::app_parent
  $app_dir       = "$app_parent$app_child_dir"
  $mysql_version = $wordpress::mysql_version
  #NOTE: This will only work as we expect it to if the db_hash contains only
  # one element. In standalone mode that should be the way it is. I think we
  # aught to check to see if db_name has more than one element and error out
  # or turn these execs into a defined type and use create resources.
  $app_hash       = $wordpress::app_hash
  $app_hash_keys  = keys($app_hash)
  $app_name       = $app_hash_keys[0]
  $db_name        = $app_hash[$app_name]['db_name']
  $db_password    = $app_hash[$app_name]['db_password']
  $db_user        = $app_hash[$app_name]['db_user']
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
      fail "Unsupported osfamily $::osfamily on $::fqdn"
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
    command  => "mysql -uroot < ${app_dir}/setup_files/create_wordpress_db.sql",
    unless   => "mysql -uroot -e \"use ${db_name}\"",
    notify   => Exec['grant_privileges'],
    require  => [ Service[ $mysql_svc ], File['wordpress_sql_script'],]
  }
  exec {'grant_privileges':
      path         => '/usr/bin:/usr/sbin:/bin',
      command      => "mysql -uroot -e \"grant all privileges on\
                      ${db_name}.* to\
                      '${db_user}'@'localhost'\
                      identified by '${db_password}'\"",
      unless       => "mysql -u${db_user}\
                      -p${db_password}\
                      -D${db_name} -hlocalhost",
      refreshonly  => true;
  }

}#end class
