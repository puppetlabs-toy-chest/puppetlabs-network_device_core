require 'spec_helper'

describe Puppet::Type.type(:vlan) do
  it "has a 'name' parameter'" do
    expect(Puppet::Type.type(:vlan).new(name: '200')[:name]).to eq('200')
  end

  it "has a 'device_url' parameter'" do
    expect(Puppet::Type.type(:vlan).new(name: '200', device_url: :device)[:device_url]).to eq(:device)
  end

  it 'is applied on device' do
    expect(Puppet::Type.type(:vlan).new(name: '200')).to be_appliable_to_device
  end

  it 'has an ensure property' do
    expect(Puppet::Type.type(:vlan).attrtype(:ensure)).to eq(:property)
  end

  it 'has a description property' do
    expect(Puppet::Type.type(:vlan).attrtype(:description)).to eq(:property)
  end

  describe 'when validating attribute values' do
    let(:provider) { stub 'provider', class: Puppet::Type.type(:vlan).defaultprovider, clear: nil }

    before(:each) do
      Puppet::Type.type(:vlan).defaultprovider.stubs(:new).returns(provider)
    end

    it 'supports :present as a value to :ensure' do
      Puppet::Type.type(:vlan).new(name: '200', ensure: :present)
    end

    it 'supports :absent as a value to :ensure' do
      Puppet::Type.type(:vlan).new(name: '200', ensure: :absent)
    end

    it 'fails if vlan name is not a number' do
      expect { Puppet::Type.type(:vlan).new(name: 'notanumber', ensure: :present) }.to raise_error(Puppet::ResourceError, %r{Parameter name failed on Vlan})
    end
  end
end
