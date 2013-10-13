# == Class: wordpress::dependent::config
#  wrapper class
#
# 
class wordpress::dependent::config {
  Anchor['wordpress::package::end'] -> Class['wordpress::dependent::config']
  #make our parameters local scope
  $config_mode = $wordpress::config_mode
  #NOTE: This will only work as we expect it to if the db_hash contains only
  # one element. In dependent mode that should be the way it is. I think we
  # aught to check to see if db_name has more than one element and error out
  # or turn these execs into a defined type and use create resources.
  $app_hash       = $wordpress::app_hash
  $app_hash_keys  = keys($app_hash)
  $app_name       = $app_hash_keys[0]
  $db_name        = $app_hash[$app_name]['db_name']
  $db_password    = $app_hash[$app_name]['db_password']
  $db_user        = $app_hash[$app_name]['db_user']
  $app_archive    = $wordpress::app_archive
  $app_child_dir  = $wordpress::app_dir
  $app_parent     = $wordpress::app_parent
  $app_dir        = "$app_parent$app_child_dir"
  $apache_pkg     = $wordpress::dependent::requirements::apache_pkg
  $site_hash      = fqdn_rand(100000000000000000000000000000000,$db_name)
  case $config_mode {
    # we support two modes here:
    # [*dependent*] which requires the puppetlabs apache and mysql modules, and
    # [*apponly*] which only requires the puppetlabs apache module
    apponly: {
    }
    dependent: {
    }
    default: {
      fail "unsupported config_mode value: \"${config_mode}\" for $::{fqdn}. Supported values are dependent, standalone, or apponly."
    }
  }#end config_mode case

  #set ordering
  File{} -> Anchor['wordpress::config::end']
  #do stuff
  file {'wordpress_application_dir':
    ensure  =>  directory,
    path    =>  $app_dir,
    before  =>  File['wordpress_setup_files_dir']
  }
  file {'wordpress_setup_files_dir':
    ensure  =>  directory,
    path    =>  "${app_dir}/setup_files",
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
    path    =>  "${app_dir}/setup_files/${app_archive}",
    notify  =>  Exec['wordpress_extract_installer'],
    source  =>  "puppet:///modules/wordpress/${app_archive}";
  }
  file {'wordpress_php_configuration':
    ensure     =>  file,
    path       =>  "${app_dir}/wp-config.php",
    content    =>  template('wordpress/wp-config.erb'),
    subscribe  =>  Exec['wordpress_extract_installer'],
  }
  file {'wordpress_htaccess_configuration':
    ensure     =>  file,
    path       =>  "${app_dir}/.htaccess",
    source     =>  'puppet:///modules/wordpress/.htaccess',
    subscribe  =>  Exec['wordpress_extract_installer'],
  }
  file {'wordpress_themes':
    ensure     => directory,
    path       => "${app_dir}/setup_files/themes",
    source     => 'puppet:///modules/wordpress/themes/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec['wordpress_extract_themes'],
    subscribe  => Exec['wordpress_extract_installer'],
  }
  file {'wordpress_plugins':
    ensure     => directory,
    path       => "${app_dir}/setup_files/plugins",
    source     => 'puppet:///modules/wordpress/plugins/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec['wordpress_extract_plugins'],
    subscribe  => Exec['wordpress_extract_installer'],
  }
  file { 'wordpress_sql_script':
    ensure   => file,
    path     => "${app_dir}/setup_files/create_wordpress_db.sql",
    content  => template('wordpress/create_wordpress_db.erb');
  }
  exec {'wordpress_extract_installer':
    command      => "unzip -o ${app_dir}/setup_files/${app_archive} -d ${app_parent}",
    refreshonly  => true,
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin']
  }
  exec {'wordpress_extract_themes':
    command      => "/bin/sh -c 'for themeindex in `ls ${app_dir}/setup_files/themes/*.zip`; do unzip -o \$themeindex -d ${app_dir}/wp-content/themes/; done'",
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    subscribe    => File['wordpress_themes'];
  }
  exec {'wordpress_extract_plugins':
    command      => "/bin/sh -c 'for pluginindex in `ls ${app_dir}/setup_files/plugins/*.zip`; do unzip -o \$pluginindex -d ${app_dir}/wp-content/plugins/; done'",
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    subscribe    => File['wordpress_plugins'];
  }

}#end class
