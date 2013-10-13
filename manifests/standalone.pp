# == Class: wordpress::standalone
# [*app_archive*]    - the archive which we should use to install wp
# [*app_child_dir*]  - The subdirectory within which wordpress should reside.
# [*app_hash*]       - The hash containing the meat of the config.
# [*app_parent*]     - The fallback directory to use as the parent directory in the absense of
#                      wp_install_parent being set in the hash. wp_install_parent will take
#                      priority.
# [*mysql_version*]  - The version of mysql to install.
# [*package_ensure*] - The value to pass to packages for their ensure parameter
#
class wordpress::standalone(
  $app_archive    = $wordpress::app_archive,
  $app_child_dir  = $wordpress::app_dir,
  $app_hash       = $wordpress::app_hash,
  $app_parent     = $wordpress::app_parent,
  $mysql_version  = $wordpress::mysql_version,
  $package_ensure = $wordpress::package_ensure)inherits wordpress
{
  #NOTE: This will only work as we expect it to if the db_hash contains only
  # one element. In standalone mode that should be the way it is. I think we
  # aught to check to see if db_name has more than one element and error out
  # or turn the execs into a defined type and use create resources.
  $app_hash_keys     = keys($app_hash)
  $app_name          = $app_hash_keys[0]
  $create_group      = $app_hash[$app_name]['create_group']
  $create_user       = $app_hash[$app_name]['create_user']
  $docroot           = $app_hash[$app_name]['docroot']
  $db_host           = $app_hash[$app_name]['db_host']
  $db_name           = $app_hash[$app_name]['db_name']
  $db_password       = $app_hash[$app_name]['db_password']
  $db_user           = $app_hash[$app_name]['db_user']
  $wp_install_parent = $app_hash[$app_name]['wp_install_parent']
  $site_hash         = fqdn_rand(100000000000000000000000000000000,$db_name)
  if $wp_install_parent {
    validate_re($wp_install_parent, '/$' )
      $parent        = $wp_install_parent
      $app_full_path = "${wp_install_parent}${app_child_dir}"
  } else {
    validate_re($app_parent, '/$' )
    $parent        = $app_parent
    $app_full_path = "${app_parent}${app_child_dir}"
  }
  if ($app_child_dir != 'wordpress') {
    fail('In standalone mode, the only supported value of app_child_dir at this time is \'wordpress\'')
  }
  case $::osfamily {
    RedHat: {
      $apacheuser = 'apache'
    }
    default: {
      $apacheuser = 'apache'
    }
  }
  include wordpress::standalone::package
  include wordpress::standalone::config
  include wordpress::standalone::service
}#end class

