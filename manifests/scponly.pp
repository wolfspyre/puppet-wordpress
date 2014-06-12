# == Class: wordpress::scponly
#  wrapper class
#
class wordpress::scponly (
  $enable_scponly = $wordpress::enable_scponly,
  $ensure         = $wordpress::package_ensure
)inherits wordpress {
  $packagename='scponly'
  $supportedval=[present,latest]

  validate_bool($enable_scponly)

  validate_re($ensure, $supportedval)


  if $enable_scponly {
    #declare the package
    package{'scponly':
      ensure => $ensure,
      alias  => 'scponly',
    }
  } else {
    fail('$::wordpress::enable_scponly must be true to manage scponly')
  }
}#end class
