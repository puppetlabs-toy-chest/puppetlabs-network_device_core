#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/provider/network_device'
require 'ostruct'

Puppet::Type.type(:vlan).provide :test, parent: Puppet::Provider::NetworkDevice do
  mk_resource_methods
  def self.lookup(_device, _name); end

  def self.device(_url)
    :device
  end
end

provider_class = Puppet::Type.type(:vlan).provider(:test)

describe provider_class do
  before(:each) do
    @resource = stub('resource', name: 'test')
    @provider = provider_class.new(@resource)
  end

  it 'is able to prefetch instances from the device' do
    expect(provider_class).to respond_to(:prefetch)
  end

  it 'has an instances method' do
    expect(provider_class).to respond_to(:instances)
  end

  describe 'when prefetching' do
    before(:each) do
      @resource = stub_everything 'resource'
      @resources = { '200' => @resource }
      provider_class.stubs(:lookup)
    end

    it 'lookups an entry for each passed resource' do
      provider_class.expects(:lookup).with { |_device, value| value == '200' }.returns nil

      provider_class.stubs(:new)
      @resource.stubs(:provider=)
      provider_class.prefetch(@resources)
    end

    describe 'resources that do not exist' do
      it 'creates a provider with :ensure => :absent' do
        provider_class.stubs(:lookup).returns(nil)
        provider_class.expects(:new).with(:device, ensure: :absent).returns 'myprovider'
        @resource.expects(:provider=).with('myprovider')
        provider_class.prefetch(@resources)
      end
    end

    describe 'resources that exist' do
      it 'creates a provider with the results of the find and ensure at present' do
        provider_class.stubs(:lookup).returns(name: '200', description: 'myvlan')

        provider_class.expects(:new).with(:device, name: '200', description: 'myvlan', ensure: :present).returns 'myprovider'
        @resource.expects(:provider=).with('myprovider')

        provider_class.prefetch(@resources)
      end
    end
  end

  describe 'when being initialized' do
    describe 'with a hash' do
      before(:each) do
        @resource_class = mock 'resource_class'
        provider_class.stubs(:resource_type).returns @resource_class

        @property_class = stub 'property_class', array_matching: :all, superclass: Puppet::Property
        @resource_class.stubs(:attrclass).with(:one).returns(@property_class)
        @resource_class.stubs(:valid_parameter?).returns true
      end

      it 'stores a copy of the hash as its vlan_properties' do
        instance = provider_class.new(:device, one: :two)
        expect(instance.former_properties).to eq(one: :two)
      end
    end
  end

  describe 'when an instance' do
    before(:each) do
      @instance = provider_class.new(:device)

      @property_class = stub 'property_class', array_matching: :all, superclass: Puppet::Property
      @resource_class = stub 'resource_class', attrclass: @property_class, valid_parameter?: true, validproperties: [:description]
      provider_class.stubs(:resource_type).returns @resource_class
    end

    it 'has a method for creating the instance' do
      expect(@instance).to respond_to(:create)
    end

    it 'has a method for removing the instance' do
      expect(@instance).to respond_to(:destroy)
    end

    it 'indicates when the instance already exists' do
      @instance = provider_class.new(:device, ensure: :present)
      expect(@instance).to be_exists
    end

    it 'indicates when the instance does not exist' do
      @instance = provider_class.new(:device, ensure: :absent)
      expect(@instance).not_to be_exists
    end

    describe 'is being flushed' do
      it 'flushes properties' do
        @instance = provider_class.new(ensure: :present, name: '200', description: 'myvlan')
        @instance.flush
        expect(@instance.properties).to be_empty
      end
    end

    describe 'is being created' do
      before(:each) do
        @rclass = mock 'resource_class'
        @rclass.stubs(:validproperties).returns([:description])
        @resource = stub_everything 'resource'
        @resource.stubs(:class).returns @rclass
        @resource.stubs(:should).returns nil
        @instance.stubs(:resource).returns @resource
      end

      it 'sets its :ensure value to :present' do
        @instance.create
        expect(@instance.properties[:ensure]).to eq(:present)
      end

      it 'sets all of the other attributes from the resource' do
        @resource.expects(:should).with(:description).returns 'myvlan'

        @instance.create
        expect(@instance.properties[:description]).to eq('myvlan')
      end
    end

    describe 'is being destroyed' do
      it 'sets its :ensure value to :absent' do
        @instance.destroy
        expect(@instance.properties[:ensure]).to eq(:absent)
      end
    end
  end
end
