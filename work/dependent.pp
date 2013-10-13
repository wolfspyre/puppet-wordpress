# == Class: wordpress::dependent
#  wrapper class
#
class wordpress::dependent {
  #these classes will behave slightly differently if config_mode has a value of dependent or apponly
  $config_mode   = $wordpress::config_mode
  include wordpress::dependent::requirements
  include wordpress::dependent::config
  #create resources
  create_resources( 'wordpress::app', $wordpress::app_hash )

}#end class

