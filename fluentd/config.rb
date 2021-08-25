PACKAGE_NAME = "fluentd"
PACKAGE_VERSION = "4.2.0"

FLUENTD_REVISION = '12de3b5a260a174fe4a419036d6e2b2e18fe7497' # v1.13.3
FLUENTD_LOCAL_GEM_REPO = "file://" + File.expand_path(File.join(__dir__, "local_gem_repo"))

# https://github.com/jemalloc/jemalloc/releases
# Use jemalloc 3.x to reduce memory usage
# See https://github.com/fluent-plugins-nursery/fluent-package-builder/issues/305
JEMALLOC_VERSION = "3.6.0"
#JEMALLOC_VERSION = "5.2.1"

# https://www.openssl.org/source/
OPENSSL_VERSION = "1.1.1k"

BUNDLER_VERSION= "2.2.23"

# https://www.ruby-lang.org/en/downloads/ (tar.gz)
#BUNDLED_RUBY_VERSION = "2.6.8"
#BUNDLED_RUBY_SOURCE_SHA256SUM = "1807b78577bc08596a390e8a41aede37b8512190e05c133b17d0501791a8ca6d"
BUNDLED_RUBY_VERSION = "2.7.4"
BUNDLED_RUBY_SOURCE_SHA256SUM = "3043099089608859fc8cce7f9fdccaa1f53a462457e3838ec3b25a7d609fbc5b"
#BUNDLED_RUBY_VERSION = "3.0.2"
#BUNDLED_RUBY_SOURCE_SHA256SUM = "5085dee0ad9f06996a8acec7ebea4a8735e6fac22f22e2d98c3f2bc3bef7e6f1"

BUNDLED_RUBY_PATCHES = [
  ["ruby-2.7/0001-Removed-the-old-executables-of-racc.patch",            ["~> 2.7.0"]],
  ["ruby-2.7/0002-Fixup-a6864f6d2f39bcd1ff04516591cc18d4027ab186.patch", ["~> 2.7.0"]],
  ["ruby-3.0/0001-ruby-resolv-Fix-confusion-of-received-response-messa.patch",   ["= 2.7.3"]],
  ["ruby-3.0/0001-ruby-resolv-Fix-confusion-of-received-response-messa.patch",   ["= 3.0.1"]],
]

# https://rubyinstaller.org/downloads/ (7-ZIP ARCHIVES)
#BUNDLED_RUBY_INSTALLER_X64_VERSION = "2.6.8-1"
#BUNDLED_RUBY_INSTALLER_X64_SHA256SUM = "e96d5a24a40c292f821b9061beef6f2337ae8b6a3f7af9502df07d3d418c8237"
BUNDLED_RUBY_INSTALLER_X64_VERSION = "2.7.4-1"
BUNDLED_RUBY_INSTALLER_X64_SHA256SUM = "2ce384d6970f28778af012b83ea82547798d758a8403dc5cc4c191eaf50ec731"
#BUNDLED_RUBY_INSTALLER_X64_VERSION = "3.0.2-1"
#BUNDLED_RUBY_INSTALLER_X64_SHA256SUM = "92894c0488ec7eab02b2ffc61a8945c4bf98d69561e170927ec30d60bee57898"

# Patch files are assumed to be for Ruby's source tree, then applied to
# lib/ruby/x.y.0 in RubyInstaller. So that "-p2" options will be passed
# to patch command.
BUNDLED_RUBY_INSTALLER_PATCHES = [
  ["ruby-3.0/0001-ruby-resolv-Fix-confusion-of-received-response-messa.patch", ["= 2.7.3"]],
  ["ruby-3.0/0001-ruby-resolv-Fix-confusion-of-received-response-messa.patch", ["= 3.0.1"]],
]
