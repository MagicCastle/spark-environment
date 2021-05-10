class base {
  include epel
  include psick
  package { 'java': }

  $instances = lookup('terraform.instances')
  $tags = lookup("terraform.instances.${::hostname}.tags")

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
  psick::netinstall { "spark-v${version}.tar.gz":
    destination_dir  => '/usr/local/spark',
    url              => "https://mirror.its.dal.ca/apache/spark/spark-${version}/spark-${version}-bin-hadoop3.2.tgz",
    retrieve_command => 'curl',
    retrieve_args    => '-L -O',
    extract_command  => 'tar -zxf',
    owner            => 'root',
    group            => 'root',
    creates          => "/usr/local/spark/spark-${version}-bin-hadoop3.2",
  }

}

node default {
  include base
}

