#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:interface) do
  it "has a 'name' parameter'" do
    expect(Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1')[:name]).to eq('FastEthernet 0/1')
  end

  it "has a 'device_url' parameter'" do
    expect(Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', device_url: :device)[:device_url]).to eq(:device)
  end

  it 'has an ensure property' do
    expect(Puppet::Type.type(:interface).attrtype(:ensure)).to eq(:property)
  end

  it 'is applied on device' do
    expect(Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1')).to be_appliable_to_device
  end

  [:description, :speed, :duplex, :native_vlan, :encapsulation, :mode, :allowed_trunk_vlans, :etherchannel, :ipaddress].each do |p|
    it "should have a #{p} property" do
      expect(Puppet::Type.type(:interface).attrtype(p)).to eq(:property)
    end
  end

  describe 'when validating attribute values' do
    before(:each) do
      @provider = stub 'provider', class: Puppet::Type.type(:interface).defaultprovider, clear: nil
      Puppet::Type.type(:interface).defaultprovider.stubs(:new).returns(@provider)
    end

    it 'supports :present as a value to :ensure' do
      Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ensure: :present)
    end

    it 'supports :shutdown as a value to :ensure' do
      Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ensure: :shutdown)
    end

    it 'supports :no_shutdown as a value to :ensure' do
      Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ensure: :no_shutdown)
    end

    describe 'especially speed' do
      it 'allows a number' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', speed: '100')
      end

      it 'allows :auto' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', speed: :auto)
      end
    end

    describe 'especially duplex' do
      it 'allows :half' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', duplex: :half)
      end

      it 'allows :full' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', duplex: :full)
      end

      it 'allows :auto' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', duplex: :auto)
      end
    end

    describe 'interface mode' do
      it 'allows :access' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', mode: :access)
      end

      it 'allows :trunk' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', mode: :trunk)
      end

      it "allows 'dynamic auto'" do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', mode: 'dynamic auto')
      end

      it "allows 'dynamic desirable'" do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', mode: 'dynamic desirable')
      end
    end

    describe 'interface encapsulation' do
      it 'allows :dot1q' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', encapsulation: :dot1q)
      end

      it 'allows :isl' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', encapsulation: :isl)
      end

      it 'allows :negotiate' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', encapsulation: :negotiate)
      end
    end

    describe 'especially ipaddress' do
      it 'allows ipv4 addresses' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: '192.168.0.1/24')
      end

      it 'allows arrays of ipv4 addresses' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: ['192.168.0.1/24', '192.168.1.0/24'])
      end

      it 'allows ipv6 addresses' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: 'f0e9::/64')
      end

      it 'allows ipv6 options' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: 'f0e9::/64 link-local')
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: 'f0e9::/64 eui-64')
      end

      it 'allows a mix of ipv4 and ipv6' do
        Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: ['192.168.0.1/24', 'f0e9::/64 link-local'])
      end

      it 'munges ip addresses to a computer format' do
        expect(Puppet::Type.type(:interface).new(name: 'FastEthernet 0/1', ipaddress: '192.168.0.1/24')[:ipaddress]).to eq([[24, IPAddr.new('192.168.0.1'), nil]])
      end
    end
  end
end
