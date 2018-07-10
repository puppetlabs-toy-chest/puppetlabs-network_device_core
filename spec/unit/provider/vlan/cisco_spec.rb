#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/provider/vlan/cisco'

provider_class = Puppet::Type.type(:vlan).provider(:cisco)

describe provider_class do
  before(:each) do
    @device = stub_everything 'device'
    @resource = stub('resource', name: '200')
    @provider = provider_class.new(@device, @resource)
  end

  it 'has a parent of Puppet::Provider::Cisco' do
    expect(provider_class).to be < Puppet::Provider::Cisco
  end

  it 'has an instances method' do
    expect(provider_class).to respond_to(:instances)
  end

  describe 'when looking up instances at prefetch' do
    before(:each) do
      @device.stubs(:command).yields(@device)
    end

    it 'delegates to the device vlans' do
      @device.expects(:parse_vlans)
      provider_class.lookup(@device, '200')
    end

    it 'returns only the given vlan' do
      @device.expects(:parse_vlans).returns('200' => { description: 'thisone' }, '1' => { description: 'nothisone' })
      expect(provider_class.lookup(@device, '200')).to eq(description: 'thisone')
    end
  end

  describe 'when an instance is being flushed' do
    it 'calls the device update_vlan method with its vlan id, current attributes, and desired attributes' do
      @instance = provider_class.new(@device, ensure: :present, name: '200', description: 'myvlan')
      @instance.description = 'myvlan2'
      @instance.resource = @resource
      @resource.stubs(:[]).with(:name).returns('200')
      device = stub_everything 'device'
      @instance.stubs(:device).returns(device)
      device.expects(:command).yields(device)
      device.expects(:update_vlan).with(@instance.name, { ensure: :present, name: '200', description: 'myvlan' },
                                        ensure: :present, name: '200', description: 'myvlan2')

      @instance.flush
    end
  end
end
