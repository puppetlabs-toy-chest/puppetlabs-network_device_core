#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/provider/cisco'

describe Puppet::Provider::Cisco do
  it 'implements a device class method' do
    expect(described_class).to respond_to(:device)
  end

  it 'creates a cisco device instance' do
    Puppet::Util::NetworkDevice::Cisco::Device.expects(:new).returns :device
    expect(described_class.device(:url)).to eq(:device)
  end
end
