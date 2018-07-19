require 'puppet/util/network_device/cisco'
require 'puppet/util/network_device/ipcalc'

# this manages setting properties to an interface in a cisco switch or router
class Puppet::Util::NetworkDevice::Cisco::Interface
  include Puppet::Util::NetworkDevice::IPCalc
  extend Puppet::Util::NetworkDevice::IPCalc

  attr_reader :transport, :name

  def initialize(name, transport)
    @name = name
    @transport = transport
  end

  # Static interface commands
  COMMANDS = {
    # property     => order, ios command/block/array
    description: [1, 'description %s'],
    speed: [2, 'speed %s'],
    duplex: [3, 'duplex %s'],
    encapsulation: [4, 'switchport trunk encapsulation %s'],
    mode: [5, 'switchport mode %s'],
    access_vlan: [6, 'switchport access vlan %s'],
    native_vlan: [7, 'switchport trunk native vlan %s'],
    allowed_trunk_vlans: [8, 'switchport trunk allowed vlan %s'],
    etherchannel: [9, ['channel-group %s', 'port group %s']],
    ipaddress: [10,
                ->(prefix, ip, option) do
                  if ip.ipv6?
                    "ipv6 address #{ip}/#{prefix} #{option}"
                  else
                    "ip address #{ip} #{netmask(Socket::AF_INET, prefix)}"
                  end
                end],
    ensure: [11, ->(value) { (value == :present) ? 'no shutdown' : 'shutdown' }],
  }.freeze

  # Update the specific interface
  def update(is = {}, should = {})
    Puppet.debug("Updating interface #{name}")
    command('conf t')
    command("interface #{name}")

    # apply changes in a defined order for cisco IOS devices
    [is.keys, should.keys].flatten.uniq.sort { |a, b| COMMANDS[a][0] <=> COMMANDS[b][0] }.each do |property|
      # Work around for old documentation which shows :native_vlan used for access vlan
      if property == :access_vlan && should[:mode] != :trunk && should[:access_vlan].nil?
        should[:access_vlan] = should[:native_vlan]
      end

      Puppet.debug("comparing #{property}: #{is[property]} == #{should[property]}")

      # They're equal, so do nothing.
      next if is[property] == should[property]

      # We're deleting it
      if should[property] == :absent || should[property].nil?
        execute(property, is[property], 'no ')
        next
      end

      # We're replacing an existing value or creating a new one
      execute(property, should[property])
    end

    command('exit')
    command('exit')
  end

  # Execute the command associated with the passed in property
  def execute(property, value, prefix = '')
    case COMMANDS[property][1]
    when Array
      COMMANDS[property][1].each do |command|
        transport.command(prefix + command % value) do |out|
          break unless out =~ %r{^%}
        end
      end
    when String
      command(prefix + COMMANDS[property][1] % value)
    when Proc
      value = [value] unless value.is_a?(Array)
      value.each do |v|
        command(prefix + COMMANDS[property][1].call(*v))
      end
    end
  end

  # Execute the given command
  def command(command)
    transport.command(command) do |out|
      if out =~ %r{^%}mo || out =~ %r{^Command rejected:}mo
        # strip off the command just sent
        error = out.sub(command, '')
        Puppet.err _("Error while executing '%{command}', device returned: %{error}") % { command: command, error: error }
      end
    end
  end
end
