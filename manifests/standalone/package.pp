# == Class: wordpress::standalone::package
#  This class installs the required packages for a standalone wordpress setup
#
class wordpress::standalone::package {
  #localize variables
  $ensure        = $wordpress::standalone::package_ensure
  $mysql_version = $wordpress::standalone::mysql_version
  #repo module end comes before  -> Class['wordpress::standalone::package']
  # end of localized variables

  #Set what packages to install
  case $::osfamily {
    RedHat: {
      $apache_pkg   = 'httpd'
      $vhost_path   = '/etc/httpd/conf.d/'
      $vhost_file   = 'wordpress.conf'
      case $::lsbmajdistrelease {
        5: {
          #wordpress requires php >5.2.4
          $remove_php   = true
          $php_pkg      = 'php53'
          $phpmysql_pkg = 'php53-mysql'
          case $mysql_version {
            5.0: {
              $mysql_pkgs = ['mysql', 'mysql-server']
            }
            5.1: {
              $mysql_pkgs = ['MySQL-server','MySQL-client','MySQL-shared-compat','MySQL-shared']
            }
            5.5: {
              $mysql_pkgs = ['MySQL-server','MySQL-client','MySQL-shared-compat','MySQL-shared']
            }
            default: {
              fail "unsupported value of \"${mysql_version}\" found for mysql_version. supported values for ${::osfamily} ${::lsbmajdistrelease} are 5.0, 5.1, and 5.5"
            }
          }#end rhel5 mysql packages case
        }
        6: {
          $remove_php   = false
          $php_pkg      = 'php'
          $phpmysql_pkg = 'php-mysql'
          case $mysql_version {
            5.1: {
              $mysql_pkgs = ['mysql', 'mysql-server']
            }
            5.5: {
              $mysql_pkgs = ['MySQL-server','MySQL-client','MySQL-shared-compat','MySQL-shared']
            }
            default: {
              fail "unsupported value of \"${mysql_version}\" found for mysql_version. supported values for ${::osfamily} ${::lsbmajdistrelease} are 5.1, and 5.5"
            }
          }#end rhel6 mysql packages case
        }
        default: {
          fail "unknown value of lsbmajdistrelease fact: \"${::lsbmajdistrelease}\" expecting 5 or 6. Is redhat-lsb installed?"
        }
      }#end OSMajor case statement
    }
    Debian: {
      $apache_pkg   = 'apache2'
      $phpmysql_pkg = 'php5-mysql'
      $php_pkg      = 'libapache2-mod-php5'
      $remove_php   = false
      $vhost_path   = '/etc/apache2/sites-enabled/'
      $vhost_file   = '000-default'
      case $mysql_version {
        5.0: {
          $mysql_pkgs = ['mysql-client','mysql-server']
        }
        default: {
          fail "unsupported value of \"${mysql_version}\" found for mysql_version. supported values for ${::osfamily} are 5.0"
        }
      }#end debian mysql_version case
    }
    default: {
      fail "unsupposed osfamily ${::osfamily} for ${::fqdn}. Supported families at this time are RedHat and Debian"
    }#end default case
  }#end osfamily case

  #all the variables are set. lets install the packages.
  #ensure unwanted php packages are removed on rh5.
  if $remove_php {
    package { ['php','php-common']:
      ensure => 'absent',
      before => Package[$php_pkg]
    }
  }
  package { $mysql_pkgs:
    ensure => $ensure
  } ->
  package { ['unzip',$php_pkg,$phpmysql_pkg]:
    ensure => $ensure,
  } ->
  package { $apache_pkg:
    ensure => $ensure,
  } -> Anchor['wordpress::package::end']
}#end class

