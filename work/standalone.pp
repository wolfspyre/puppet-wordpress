# == Class: wordpress::standalone
#  wrapper class
#
class wordpress::standalone {
  include wordpress::standalone::package
  include wordpress::standalone::config
  include wordpress::standalone::service
}#end class

