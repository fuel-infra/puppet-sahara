require 'spec_helper_acceptance'

describe 'basic sahara' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      include ::openstack_integration
      include ::openstack_integration::repos
      include ::openstack_integration::rabbitmq
      include ::openstack_integration::mysql
      include ::openstack_integration::keystone

      rabbitmq_user { 'sahara':
        admin    => true,
        password => 'an_even_bigger_secret',
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq'],
      }

      rabbitmq_user_permissions { 'sahara@/':
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        require              => Class['rabbitmq'],
      }

      # Sahara resources
      class { '::sahara::db::mysql':
        password => 'a_big_secret',
      }
      class { '::sahara':
        debug                 => true,
        default_transport_url => 'rabbit://sahara:an_even_bigger_secret@127.0.0.1:5672/',
        rpc_backend           => 'rabbit',
        database_connection   => 'mysql+pymysql://sahara:a_big_secret@127.0.0.1/sahara?charset=utf8',
      }
      class { '::sahara::keystone::authtoken':
        password => 'a_big_secret',
      }
      class { '::sahara::service::api': }
      class { '::sahara::service::engine': }
      class { '::sahara::keystone::auth':
        password => 'a_big_secret',
      }
      class { '::sahara::client': }
      class { '::sahara::notify': }
      EOS


      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    if os[:family].casecmp('RedHat') == 0
      describe port(8386) do
        it { is_expected.to be_listening.with('tcp') }
      end
    end

  end
end
