require 'spec_helper'

require 'puppet/util/network_device/transport/ssh'

describe Puppet::Util::NetworkDevice::Transport::Ssh, if: Puppet.features.ssh? do
  before(:each) do
    @transport = Puppet::Util::NetworkDevice::Transport::Ssh.new
  end

  it 'handles login through the transport' do
    expect(@transport).to be_handles_login
  end

  it 'connects to the given host and port' do
    Net::SSH.expects(:start).with { |host, _user, args| host == 'localhost' && args[:port] == 22 }.returns stub_everything
    @transport.host = 'localhost'
    @transport.port = 22

    @transport.connect
  end

  it 'connects using the given username and password' do
    Net::SSH.expects(:start).with { |_host, user, args| user == 'user' && args[:password] == 'pass' }.returns stub_everything
    @transport.user = 'user'
    @transport.password = 'pass'

    @transport.connect
  end

  it 'raises a Puppet::Error when encountering an authentication failure' do
    Net::SSH.expects(:start).raises Net::SSH::AuthenticationFailed
    @transport.host = 'localhost'
    @transport.user = 'user'

    expect { @transport.connect }.to raise_error Puppet::Error
  end

  describe 'when connected' do
    before(:each) do
      @ssh = stub_everything 'ssh'
      @channel = stub_everything 'channel'
      Net::SSH.stubs(:start).returns @ssh
      @ssh.stubs(:open_channel).yields(@channel)
      @transport.stubs(:expect)
    end

    it 'opens a channel' do
      @ssh.expects(:open_channel)

      @transport.connect
    end

    it 'requests a pty' do
      @channel.expects(:request_pty)

      @transport.connect
    end

    it 'creates a shell channel' do
      @channel.expects(:send_channel_request).with('shell')
      @transport.connect
    end

    it 'raises an error if shell channel creation fails' do
      @channel.expects(:send_channel_request).with('shell').yields(@channel, false)
      expect { @transport.connect }.to raise_error(RuntimeError, %r{failed to open ssh shell channel})
    end

    it 'registers an on_data and on_extended_data callback' do
      @channel.expects(:send_channel_request).with('shell').yields(@channel, true)
      @channel.expects(:on_data)
      @channel.expects(:on_extended_data)
      @transport.connect
    end

    it 'accumulates data to the buffer on data' do
      @channel.expects(:send_channel_request).with('shell').yields(@channel, true)
      @channel.expects(:on_data).yields(@channel, 'data')

      @transport.connect
      expect(@transport.buf).to eq('data')
    end

    it 'accumulates data to the buffer on extended data' do
      @channel.expects(:send_channel_request).with('shell').yields(@channel, true)
      @channel.expects(:on_extended_data).yields(@channel, 1, 'data')

      @transport.connect
      expect(@transport.buf).to eq('data')
    end

    it 'marks eof on close' do
      @channel.expects(:send_channel_request).with('shell').yields(@channel, true)
      @channel.expects(:on_close).yields(@channel)

      @transport.connect
      expect(@transport).to be_eof
    end

    it 'expects output to conform to the default prompt' do
      @channel.expects(:send_channel_request).with('shell').yields(@channel, true)
      @transport.expects(:default_prompt).returns('prompt')
      @transport.expects(:expect).with('prompt')
      @transport.connect
    end

    it 'starts the ssh loop' do
      @ssh.expects(:loop)
      @transport.connect
    end
  end

  describe 'when closing' do
    before(:each) do
      @ssh = stub_everything 'ssh'
      @channel = stub_everything 'channel'
      Net::SSH.stubs(:start).returns @ssh
      @ssh.stubs(:open_channel).yields(@channel)
      @channel.stubs(:send_channel_request).with('shell').yields(@channel, true)
      @transport.stubs(:expect)
      @transport.connect
    end

    it 'closes the channel' do
      @channel.expects(:close)
      @transport.close
    end

    it 'closes the ssh session' do
      @ssh.expects(:close)
      @transport.close
    end
  end

  describe 'when sending commands' do
    before(:each) do
      @ssh = stub_everything 'ssh'
      @channel = stub_everything 'channel'
      Net::SSH.stubs(:start).returns @ssh
      @ssh.stubs(:open_channel).yields(@channel)
      @channel.stubs(:send_channel_request).with('shell').yields(@channel, true)
      @transport.stubs(:expect)
      @transport.connect
    end

    it 'sends data to the ssh channel' do
      @channel.expects(:send_data).with("data\n")
      @transport.command('data')
    end

    it 'expects the default prompt afterward' do
      @transport.expects(:default_prompt).returns('prompt')
      @transport.expects(:expect).with('prompt')
      @transport.command('data')
    end

    it 'expects the given prompt' do
      @transport.expects(:expect).with('myprompt')
      @transport.command('data', prompt: 'myprompt')
    end

    it 'yields the buffer output to given block' do
      @transport.expects(:expect).yields('output')
      @transport.command('data') do |out|
        expect(out).to eq('output')
      end
    end

    it 'returns buffer output' do
      @transport.expects(:expect).returns('output')
      expect(@transport.command('data')).to eq('output')
    end
  end

  describe 'when expecting output' do
    before(:each) do
      @connection = stub_everything 'connection'
      @socket = stub_everything 'socket'
      transport = stub 'transport', socket: @socket
      @ssh = stub_everything 'ssh', transport: transport
      @channel = stub_everything 'channel', connection: @connection
      @transport.ssh = @ssh
      @transport.channel = @channel
    end

    it 'processes the ssh event loop' do
      IO.stubs(:select)
      @transport.buf = 'output'
      @transport.expects(:process_ssh)
      @transport.expect(%r{output})
    end

    it 'returns the output' do
      IO.stubs(:select)
      @transport.buf = 'output'
      @transport.stubs(:process_ssh)
      expect(@transport.expect(%r{output})).to eq('output')
    end

    it 'returns the output' do
      IO.stubs(:select)
      @transport.buf = 'output'
      @transport.stubs(:process_ssh)
      expect(@transport.expect(%r{output})).to eq('output')
    end

    describe 'when processing the ssh loop' do
      it 'advances one tick in the ssh event loop and exit on eof' do
        @transport.buf = ''
        @connection.expects(:process).then.raises(EOFError)
        @transport.process_ssh
      end
    end
  end
end
