class base {
  include epel
  include psick
  package { 'java': }

}

node default {
  include base
}

