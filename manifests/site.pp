class base {
  include epel
  include psick
  package { 'java': }

  $instances = lookup('terraform.instances')
  $host_template = @(END)
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
<% @instances.each do |key, values| -%>
<%= values['local_ip'] %> <%= key %> <% if values['tags'].include?('puppet') %>puppet<% end %>
<% end -%>
END

  file { '/etc/hosts':
    ensure  => file,
    content => inline_template($host_template)
  }

  $version = '3.1.1'
  psick::netinstall { "spark-${version}":
    destination_dir  => '/opt',
    url              => "https://mirror.its.dal.ca/apache/spark/spark-${version}/spark-${version}-bin-hadoop3.2.tgz",
    retrieve_command => 'curl',
    retrieve_args    => '-L -O',
    extract_command  => 'tar -zxf',
    owner            => 'root',
    group            => 'root',
    creates          => "/opt/spark-${version}-bin-hadoop3.2",
  }

  $master_ip = lookup('terraform.tag_ip.master.0')
  $cores = $processorcount
  $memory = round($memoryfree_mb / 100) * 100
  file { "/opt/spark-${version}-bin-hadoop3.2/conf/spark-env.sh":
    content => @("END")
#!/usr/bin/env bash
SPARK_MASTER_HOST=${master_ip}
SPARK_WORKER_CORES=${cores}
SPARK_WORKER_MEMORY=${memory}M
END
  }

}

class master {
  $version = '3.1.1'

  file { '/etc/systemd/system/spark-master.service':
    content => @("END")
[Unit]
Description=Apache Spark Master
After=network.target
After=systemd-user-sessions.service
After=network-online.target

[Service]
User=root
Type=forking
ExecStart=/opt/spark-${version}-bin-hadoop3.2/sbin/start-master.sh
ExecStop=/opt/spark-${version}-bin-hadoop3.2/sbin/stop-master.sh
TimeoutSec=30
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
END
  }

  service { 'spark-master':
    ensure => running,
    enable => true,
    require => File['/etc/systemd/system/spark-master.service']
  }
}

class worker {
  $version = '3.1.1'
  file { '/etc/systemd/system/spark-worker.service':
    content => @("END")
[Unit]
Description=Apache Spark Worker
After=network.target
After=systemd-user-sessions.service
After=network-online.target

[Service]
User=root
Type=forking
ExecStart=/opt/spark-${version}-bin-hadoop3.2/sbin/start-worker.sh
ExecStop=/opt/spark-${version}-bin-hadoop3.2/sbin/stop-worker.sh
TimeoutSec=30
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
END
  }

  service { 'spark-worker':
    ensure => running,
    enable => true,
    require => File['/etc/systemd/system/spark-worker.service']
  }
}

node default {
  include base
  $tags = lookup("terraform.instances.${::hostname}.tags")
  if 'master' in $tags {
    include master
  } elsif 'worker' in $tags {
    include worker
  }
}

