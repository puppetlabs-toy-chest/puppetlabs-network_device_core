require 'spec_helper'

if Puppet.features.telnet?
  require 'puppet/util/network_device/transport/telnet'

  describe Puppet::Util::NetworkDevice::Transport::Telnet do
    let(:transport) { Puppet::Util::NetworkDevice::Transport::Telnet.new }

    before(:each) do
      TCPSocket.stubs(:open).returns stub_everything('tcp')
    end

    it 'does not handle login through the transport' do
      expect(transport).not_to be_handles_login
    end

    it 'does not open any files' do
      File.expects(:open).never
      transport.host = 'localhost'
      transport.port = 23

      transport.connect
    end

    it 'connects to the given host and port' do
      Net::Telnet.expects(:new).with { |args| args['Host'] == 'localhost' && args['Port'] == 23 }.returns stub_everything
      transport.host = 'localhost'
      transport.port = 23

      transport.connect
    end

    it 'connects and specify the default prompt' do
      transport.default_prompt = 'prompt'
      Net::Telnet.expects(:new).with { |args| args['Prompt'] == 'prompt' }.returns stub_everything
      transport.host = 'localhost'
      transport.port = 23

      transport.connect
    end

    describe 'when connected' do
      let(:telnet) { stub_everything 'telnet' }

      before(:each) do
        Net::Telnet.stubs(:new).returns(telnet)
        transport.connect
      end

      it 'sends line to the telnet session' do
        telnet.expects(:puts).with('line')
        transport.send('line')
      end

      describe 'when expecting output' do
        it 'waitfors output on the telnet session' do
          telnet.expects(:waitfor).with(%r{regex})
          transport.expect(%r{regex}) # rubocop:disable RSpec/ExpectActual
        end

        it 'returns telnet session output' do
          telnet.expects(:waitfor).returns('output')
          expect(transport.expect(%r{regex})).to eq('output') # rubocop:disable RSpec/ExpectActual
        end

        it 'yields telnet session output to the given block' do
          telnet.expects(:waitfor).yields('output')
          transport.expect(%r{regex}) { |out| expect(out).to eq('output') } # rubocop:disable RSpec/ExpectActual
        end
      end
    end

    describe 'when closing' do
      let(:telnet) { stub_everything 'telnet' }

      before(:each) do
        Net::Telnet.stubs(:new).returns(telnet)
        transport.connect
      end

      it 'closes the telnet session' do
        telnet.expects(:close)
        transport.close
      end
    end
  end
end
