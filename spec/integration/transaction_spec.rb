#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/transaction'

describe Puppet::Transaction do

  before do
    Puppet::Util::Storage.stubs(:store)
  end

  it "should not apply device resources on normal host" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:interface).new :name => "FastEthernet 0/1"
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::RandomPrioritizer.new)
    transaction.for_network_device = false

    transaction.expects(:apply).never.with(resource, nil)

    transaction.evaluate
    expect(transaction.resource_status(resource)).to be_skipped
  end

  it "should apply device resources on device" do
    catalog = Puppet::Resource::Catalog.new
    resource = Puppet::Type.type(:interface).new :name => "FastEthernet 0/1"
    catalog.add_resource resource

    transaction = Puppet::Transaction.new(catalog, nil, Puppet::Graph::RandomPrioritizer.new)
    transaction.for_network_device = true

    transaction.expects(:apply).with(resource, nil)

    transaction.evaluate
    expect(transaction.resource_status(resource)).not_to be_skipped
  end
end
