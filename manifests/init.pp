# Class: nubis_grafana
# ===========================
#
# Full description of class nubis_grafana here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'nubis_grafana':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2017 Your name here, unless otherwise noted.
#
class nubis_grafana($version = '3.1.1-1470047149', $tag_name='monitoring', $project=undef, $dashboards_dir=undef) {

  if ($project) {
    $grafana_project = $project
  }
  else {
    $grafana_project = $::project_name
  }

  package {'crudini':
    ensure => present,
  }

class { 'grafana':
  install_method => 'repo',
  version        => $version,
  cfg            => {
    app_mode          => 'production',
    'server'          => {
      protocol => 'http',
      root_url => '/grafana',
    },
    'auth.anonymous'  => {
      enabled => true,
    },
    # Needs to be disabled for traefik, enabled for grafana_datasource, hurgh
    'auth.basic'      => {
      enabled => true,
    },
    users             => {
      allow_sign_up => false,
    },
    'dashboards.json' => {
      enabled => true,
    },
  },
}->
exec {'wait-for grafana startup':
  command => '/bin/sleep 15',
}->
grafana_datasource { 'prometheus':
  grafana_url      => 'http://localhost:3000',
  grafana_user     => 'admin',
  grafana_password => 'admin',
  type             => 'prometheus',
  url              => 'http://localhost:81/prometheus',
  access_mode      => 'proxy',
  is_default       => true,
}->
exec { 'disable basic auth':
  command => '/usr/bin/crudini --set /etc/grafana/grafana.ini auth.basic enabled false',
  require => [
    Package['crudini'],
  ]
}->
exec {'enable proxy support':
  command => '/bin/echo ". /etc/profile.d/proxy.sh" >> /etc/default/grafana-server'
}

  if ($dashboards_dir) {
    $dashboard_src = $dashboards_dir
  }
  else {
    $dashboard_src = "puppet:///modules/${module_name}/dashboards"
  }

  file { '/var/lib/grafana/dashboards':
  ensure  => directory,
  owner   => grafana,
  group   => grafana,
  mode    => '0640',
  recurse => true,
  purge   => true,
  source  => $dashboard_src,
  require => [
    Class['grafana'],
  ]
  }

  file { '/etc/consul/svc-grafana.json':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${module_name}/svc-grafana.json.tmpl"),
  }


}
