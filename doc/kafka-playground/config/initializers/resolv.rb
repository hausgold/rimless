# frozen_string_literal: true

require 'resolv'

# Check if we're running in an environment without IPv6 support, requesting
# IPv6 nameservers for mDNS will result in the following error:
#
#   Errno::EADDRNOTAVAIL: Cannot assign requested address
#                         sendto(2) for "ff02::fb" port 5353
#
# This is confusing, as we expect a mDNS lookup failure to look like this:
#
#   no address for schema-registry.message-bus.local (Resolv::ResolvError)
#
# Therefore, we drop the IPv6 mDNS nameserver address.
if File.empty?('/proc/net/if_inet6')
  Resolv::MDNS::Addresses.delete_if do |(ip, _port)|
    ip == Resolv::MDNS::AddressV6
  end
end

# A custom resolver factory for our local environments.
# See: https://github.com/excon/excon/pull/897
class LocalResolverFactory
  # Create a new +Resolv+ resolver instance, configured for our local
  # environment.
  #
  # @return [Resolv] the new resolver instance
  def self.create_resolver
    Resolv.new(create_resolvers)
  end

  # Create new resolvers for our local environment (hosts, mDNS, DNS).
  #
  # @return [Array<Resolv::Hosts, Resolv::MDNS, Resolv::DNS>] the new
  #   resolvers to combine
  def self.create_resolvers
    # The misleading Errno::EADDRNOTAVAIL, catches an awful long timeout for
    # the mDNS resolver (75 seconds). But when we're going to remove the IPv6
    # mDNS nameserver address, we have to configure more meaningful timeouts
    # for mDNS.
    mdns_resolver = Resolv::MDNS.new
    mdns_resolver.timeouts = 3

    [
      Resolv::Hosts.new,
      mdns_resolver,
      Resolv::DNS.new
    ]
  end
end

# Replace the default resolvers
Resolv::DefaultResolver.replace_resolvers(
  LocalResolverFactory.create_resolvers
)

# Configure Excon to use our custom resolver factory
Excon.defaults[:resolver_factory] = LocalResolverFactory
