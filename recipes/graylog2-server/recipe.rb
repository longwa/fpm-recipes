require_relative '../tools'

class Graylog2Server < FPM::Cookery::Recipe
  include Tools

  description 'Graylog2 server'

  name     'graylog2-server'
  version  data.version
  revision data.revision
  homepage data.homepage
  arch     'all'

  source data.source
  sha256 data.sha256

  maintainer data.maintainer
  vendor     data.vendor
  license    data.license

  config_files '/etc/graylog2/server/server.conf',
               '/etc/graylog2/server/log4j.xml'

  platforms [:ubuntu, :debian] do
    section 'net'
    depends 'java7-runtime-headless | openjdk-7-jre-headless', 'uuid-runtime'

    config_files '/etc/default/graylog2-server'

    post_install "files/#{platform}/post-install"
    post_uninstall "files/#{platform}/post-uninstall"
  end

  platforms [:ubuntu] do
    config_files '/etc/init/graylog2-server.conf'
  end

  platforms [:debian] do
    config_files '/etc/init.d/graylog2-server',
                 '/etc/logrotate.d/graylog2-server'
  end

  platforms [:centos] do
    depends 'java >= 1:1.7.0', 'util-linux-ng'

    config_files '/etc/init.d/graylog2-server',
                 '/etc/sysconfig/graylog2-server'

    post_install 'files/centos/post-install'
    pre_uninstall 'files/centos/pre-uninstall'
  end

  def build
    patch(workdir('patches/graylog2-server.conf.patch'))
    patch(workdir('patches/graylog2-es-timestamp-fixup.patch'))
  end

  def install
    etc('graylog2/server').install 'graylog2.conf.example', 'server.conf'
    etc('graylog2/server').install file('log4j.xml')

    case FPM::Cookery::Facts.platform
    when :ubuntu
      etc('init').install osfile('upstart.conf'), 'graylog2-server.conf'
      etc('default').install osfile('default'), 'graylog2-server'
    when :debian
      etc('init.d').install osfile('init.d'), 'graylog2-server'
      etc('init.d/graylog2-server').chmod(0755)
      etc('default').install osfile('default'), 'graylog2-server'
      etc('logrotate.d').install osfile('logrotate'), 'graylog2-server'
    when :centos
      etc('init.d').install osfile('init.d'), 'graylog2-server'
      etc('init.d/graylog2-server').chmod(0755)
      etc('sysconfig').install osfile('sysconfig'), 'graylog2-server'
    end

    share('graylog2-server').install 'graylog2.jar'
    share('graylog2-server/plugin').mkpath
    share('graylog2-server/bin').install 'bin/graylog2-es-timestamp-fixup'
    share('graylog2-server').install 'lib'

    # Remove unused sigar libs.
    sigar_cleanup(share('graylog2-server/lib/sigar'))
  end
end
