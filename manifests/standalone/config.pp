# == Class: wordpress::standalone::config
#  wrapper class
#
class wordpress::standalone::config {
  Anchor['wordpress::package::end'] -> Class['wordpress::standalone::config']
  include wordpress::standalone
  $apache_pkg    = $wordpress::standalone::package::apache_pkg
  $app_archive   = $wordpress::standalone::app_archive
  $app_full_path = $wordpress::standalone::app_full_path
  $app_hash      = $wordpress::standalone::app_hash
  $app_name      = $wordpress::standalone::app_name
  $create_group  = $wordpress::standalone::create_group
  $create_user   = $wordpress::standalone::create_user
  $docroot       = $wordpress::standalone::docroot
  $db_host       = $wordpress::standalone::db_host
  $db_name       = $wordpress::standalone::db_name
  $db_password   = $wordpress::standalone::db_password
  $db_user       = $wordpress::standalone::db_user
  $parent        = $wordpress::standalone::parent
  $site_hash     = $wordpress::standalone::site_hash
  #dependent variables
  #set OS variables
  case $::osfamily {
    RedHat: {
      $vhost_path  = '/etc/httpd/conf.d/wordpress.conf'
    }
    Debian: {
      $vhost_path  = '/etc/apache2/sites-enabled/000-default'
    }
    default: {
      fail "${::osfamily} is not supported for the wordpress::standalone module"
    }
  }
  #set ordering
  File{
    owner  => $wp_owner,
    group  => $wp_group,
    mode   => '0644',
    before => Anchor['wordpress::config::end'],
  }
  #do stuff

  #user/group
  if ($create_user == true) {
    $wp_owner = $app_hash[$app_name]['wp_owner']
    user { $wp_owner:
      ensure  => 'present',
      comment => 'Wordpress_user',
      home    => $docroot,
      shell   => '/dev/null',
    } -> File[$app_full_path]
  }else {
    $wp_owner = $wordpress::standalone::apacheuser
  }
  if ($create_group ==true) {
    $wp_group       = $app_hash[$app_name]['wp_group']
    group { $wp_group:
      ensure  => 'present',
    } -> File[$app_full_path]
  }else {
    $wp_group = $wordpress::standalone::apacheuser
  }
  #directories and files
  $dirs = [$parent, $app_full_path]
  file {$dirs:
    ensure  =>  directory,
    before  =>  File['wordpress_setup_files_dir']
  }
  file {'wordpress_setup_files_dir':
    ensure  =>  directory,
    path    =>  "${app_full_path}/setup_files",
    before  =>  File[
      'wordpress_php_configuration',
      'wordpress_themes',
      'wordpress_plugins',
      'wordpress_installer',
      'wordpress_htaccess_configuration',
      'wordpress_sql_script'
      ]
  }
  file {'wordpress_installer':
    ensure  =>  file,
    path    =>  "${app_full_path}/setup_files/${app_archive}",
    notify  =>  Exec['wordpress_extract_installer'],
    source  =>  "puppet:///modules/wordpress/${app_archive}";
  }
  file {'wordpress_php_configuration':
    ensure     =>  file,
    path       =>  "${app_full_path}/wp-config.php",
    content    =>  template('wordpress/wp-config.erb'),
    subscribe  =>  Exec['wordpress_extract_installer'],
  }
  file {'wordpress_htaccess_configuration':
    ensure     =>  file,
    path       =>  "${app_full_path}/.htaccess",
    source     =>  'puppet:///modules/wordpress/.htaccess',
    subscribe  =>  Exec['wordpress_extract_installer'],
  }
  file {'wordpress_themes':
    ensure     => directory,
    path       => "${app_full_path}/setup_files/themes",
    source     => 'puppet:///modules/wordpress/themes/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec['wordpress_extract_themes'],
    subscribe  => Exec['wordpress_extract_installer'],
  }
  file {'wordpress_plugins':
    ensure     => directory,
    path       => "${app_full_path}/setup_files/plugins",
    source     => 'puppet:///modules/wordpress/plugins/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec['wordpress_extract_plugins'],
    subscribe  => Exec['wordpress_extract_installer'],
  }
  file {"${app_full_path}/wp-content/uploads":
    ensure   => directory,
    path     => "${app_full_path}/wp-content/uploads",
    mode     => '0755',
    require  => Exec['wordpress_extract_installer'],
  }
  file {'wordpress_vhost':
    ensure   => file,
    path     => $vhost_path,
    content  => template('wordpress/standalone_vhost.conf.erb'),
    replace  => true,
    require  => Package[$apache_pkg],
  }
  file { 'wordpress_sql_script':
    ensure   => file,
    path     => "${app_full_path}/setup_files/create_wordpress_db.sql",
    content  => template('wordpress/create_wordpress_db.erb');
  }

  #execs
  exec {'wordpress_extract_installer':
    command      => "unzip -o ${app_full_path}/setup_files/${app_archive} -d ${parent}",
    refreshonly  => true,
    require      => Package['unzip'],
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin']
  }
  exec {'wordpress_extract_themes':
    command      => "/bin/sh -c 'for themeindex in `ls ${app_full_path}/setup_files/themes/*.zip`; do unzip -o \$themeindex -d ${app_full_path}/wp-content/themes/; done'",
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    require      => Package['unzip'],
    subscribe    => File['wordpress_themes'];
  }
  exec {'wordpress_extract_plugins':
    command      => "/bin/sh -c 'for pluginindex in `ls ${app_full_path}/setup_files/plugins/*.zip`; do unzip -o \$pluginindex -d ${app_full_path}/wp-content/plugins/; done'",
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    require      => Package['unzip'],
    subscribe    => File['wordpress_plugins'];
  }

}#end class
