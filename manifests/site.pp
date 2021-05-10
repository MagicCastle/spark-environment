class base {
  include epel
  include psick
  package { 'java': }

  $version = '3.1.1'
  psick::netinstall { "spark-v${version}.tar.gz":
    destination_dir => '/usr/local/spark',
    url             => "https://mirror.its.dal.ca/apache/spark/spark-${version}/spark-${version}-bin-hadoop3.2.tgz",
    extract_command => 'tar -zxf',
    owner           => 'root',
    group           => 'root',
    creates         => "/usr/local/spark/spark-${version}-bin-hadoop3.2",
  }
}

node default {
  include base
}

