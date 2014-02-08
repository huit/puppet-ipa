# Class: ipa::service
#
# Realizes the IPA service for dependency handling
class ipa::service {
  realize Service['ipa']
}
