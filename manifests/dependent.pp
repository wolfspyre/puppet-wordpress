# == Class: wordpress::dependent
#  wrapper class
# [*app_archive*]    - the archive which we should use to install wp
# [*app_child_dir*]  - The subdirectory within which wordpress should reside.
# [*app_hash*]       - The hash containing the meat of the config.
# [*app_parent*]     - The fallback directory to use as the parent directory in the absense of
#                      wp_install_parent being set in the hash. wp_install_parent will take
#                      priority.
# [*config_mode*]    - Supported values here are apponly and dependent
# [*package_ensure*] - The value to pass to packages for their ensure parameter
class wordpress::dependent(
  $app_archive    = $wordpress::app_archive,
  $app_child_dir  = $wordpress::app_dir,
  $app_hash       = $wordpress::app_hash,
  $app_parent     = $wordpress::app_parent,
  $config_mode    = $wordpress::config_mode,
  $package_ensure = $wordpress::package_ensure)inherits wordpress
{
#input validation
  $supported_modes = ['apponly', 'dependent']
  validate_re($config_mode, $supported_modes, "The dependent class only supports the values of \'dependent\' and \'apponly\' for the config_mode parameter. ${config_mode} is not a supported value")
  validate_hash($app_hash)
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
  validate_bool($create_group)
  validate_bool($create_user)
  if $wp_install_parent {
    validate_re($wp_install_parent, '/$' )
      $parent        = $wp_install_parent
      $app_full_path = "${wp_install_parent}${app_child_dir}"
  } else {
    validate_re($app_parent, '/$' )
    $parent        = $app_parent
    $app_full_path = "${app_parent}${app_child_dir}"
  }
  #these classes will behave slightly differently if config_mode has a value of dependent or apponly
  include wordpress::dependent::requirements
  #include wordpress::dependent::config
  #create resources
  $overrides = {
    'app_archive'       => $app_archive,
    'app_install_dir'   => $app_child_dir,
    'wp_install_parent' => $parent,
    'config_mode'       => $config_mode
  }
  create_resources( 'wordpress::app', $app_hash, $overrides)

}#end class

