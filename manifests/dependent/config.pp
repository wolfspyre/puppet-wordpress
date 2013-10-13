# == Class: wordpress::dependent::config
#  wrapper class
#
#
class wordpress::dependent::config {

#deprecated. all done in the app defined type.
#Anchor['wordpress::package::end'] -> Class['wordpress::dependent::config']
#  #make our parameters local scope
#
#  $apache_pkg     = $wordpress::dependent::requirements::apache_pkg
#  $app_archive    = $wordpress::dependent::app_archive
#  $app_child_dir  = $wordpress::dependent::app_dir
#  $app_full_path  = $wordpress::dependent::app_full_path
#  $app_hash       = $wordpress::dependent::app_hash
#  $config_mode    = $wordpress::dependent::config_mode
#  $db_host        = $wordpress::dependent::db_host
#  $db_name        = $wordpress::dependent::db_name
#  $db_password    = $wordpress::dependent::db_password
#  $db_user        = $wordpress::dependent::db_user
#  $parent         = $wordpress::dependent::parent
#  $site_hash      = $wordpress::dependent::site_hash
#
#  #set ordering
#  File{} -> Anchor['wordpress::config::end']
#  #do stuff
#  file {$app_full_path:
#    ensure  =>  directory,
#    path    =>  $app_full_path,
#   before  =>  File['wordpress_setup_files_dir']
# }
#  file {'wordpress_setup_files_dir':
#    ensure  =>  directory,
#    path    =>  "${app_full_path}/setup_files",
#    before  =>  File[
#     'wordpress_php_configuration',
#     'wordpress_themes',
#      'wordpress_plugins',
#      'wordpress_installer',
#      'wordpress_htaccess_configuration',
#      'wordpress_sql_script'
#      ]
#  }
#  file {'wordpress_installer':
#    ensure  =>  file,
#    path    =>  "${app_full_path}/setup_files/${app_archive}",
#    notify  =>  Exec['wordpress_extract_installer'],
#    source  =>  "puppet:///modules/wordpress/${app_archive}";
#  }
#  file {'wordpress_php_configuration':
#    ensure     =>  file,
#    path       =>  "${app_full_path}/wp-config.php",
#    content    =>  template('wordpress/wp-config.erb'),
#    subscribe  =>  Exec['wordpress_extract_installer'],
#  }
#  file {'wordpress_htaccess_configuration':
#    ensure     =>  file,
#    path       =>  "${app_full_path}/.htaccess",
#    source     =>  'puppet:///modules/wordpress/.htaccess',
#    subscribe  =>  Exec['wordpress_extract_installer'],
#  }
#  file {'wordpress_themes':
#    ensure     => directory,
#    path       => "${app_full_path}/setup_files/themes",
#    source     => 'puppet:///modules/wordpress/themes/',
#    recurse    => true,
#    purge      => true,
#    ignore     => '.svn',
#    notify     => Exec['wordpress_extract_themes'],
#    subscribe  => Exec['wordpress_extract_installer'],
#  }
#  file {'wordpress_plugins':
#    ensure     => directory,
#    path       => "${app_full_path}/setup_files/plugins",
#    source     => 'puppet:///modules/wordpress/plugins/',
#    recurse    => true,
#    purge      => true,
#    ignore     => '.svn',
#    notify     => Exec['wordpress_extract_plugins'],
#    subscribe  => Exec['wordpress_extract_installer'],
#  }
#  file { 'wordpress_sql_script':
#    ensure   => file,
#    path     => "${app_full_path}/setup_files/create_wordpress_db.sql",
#    content  => template('wordpress/create_wordpress_db.erb');
#  }
#  exec {'wordpress_extract_installer':
#    command      => "unzip -o ${app_full_path}/setup_files/${app_archive} -d ${parent}",
#    refreshonly  => true,
#    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin']
#  }
#  exec {'wordpress_extract_themes':
#    command      => "/bin/sh -c 'for themeindex in `ls ${app_full_path}/setup_files/themes/*.zip`; do unzip -o \$themeindex -d ${app_full_path}/wp-content/themes/; done'",
#    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
#    refreshonly  => true,
#    subscribe    => File['wordpress_themes'];
#  }
#  exec {'wordpress_extract_plugins':
#    command      => "/bin/sh -c 'for pluginindex in `ls ${app_full_path}/setup_files/plugins/*.zip`; do unzip -o \$pluginindex -d ${app_full_path}/wp-content/plugins/; done'",
#    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
#    refreshonly  => true,
#    subscribe    => File['wordpress_plugins'];
#  }

}#end class
