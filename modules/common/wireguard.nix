{ pkgs, config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  # isServer = thisMachine.staticIp != null;
  isServer = machine: ((machine.staticIp4 != null) || (machine.staticIp6 != null));
  # If this is a server: All other machines including servers and clients
  # If this is a client: Only other machines that are servers
  otherMachines = lib.attrValues (lib.filterAttrs (name: machine: name != config.networking.hostName && ((isServer thisMachine) || (isServer machine))) config.machines);

  ipv6_prefix = "fd10:2030";
in
{
  imports = [
    ../machines.nix
  ];

  options = with lib; {
    customWireguardPrivateKeyFile = mkOption {
      default = [ ];
      description = lib.mdDoc "The wireguard private key for this machine. Should only be set if the secrets of that machine are not managed in this repo";
      type = with types; attrsOf (submodule machineOpts);
    };
    customWireguardPskFile = mkOption {
      default = [ ];
      description = lib.mdDoc "Information about the machines in the network. Should only be set if the secrets of that machine are not managed in this repo";
      type = with types; attrsOf (submodule machineOpts);
    };
  };

  config = {
    age.secrets.wireguard_private_key = {
      file = ../../secrets + "/${config.networking.hostName}_wireguard.age";
      mode = "0444";
    };
    age.secrets.shared_wireguard_psk = {
      file = ../../secrets/shared_wireguard_psk.age;
      mode = "0444";
    };

    networking = {
      # Open firewall port for WireGuard.
      firewall = {
        allowedUDPPorts = [ 51820 ];
        interfaces."antibuilding".allowedTCPPorts = [ 22 ];
      };

      # Add all machines to the hosts file.
      hosts = builtins.listToAttrs (builtins.concatMap
        (machine: [
          {
            name = "${ipv6_prefix}::${builtins.toString machine.address}";
            value = [ "${machine.name}.antibuild.ing" machine.name ];
          }
        ]
        # Set hostnames for the endpoints of the machines with static IPs.
        ++ (if machine.staticIp4 != null then [
          {
            name = machine.staticIp4;
            value = [ "${machine.name}.endpoint.zebre.us" ];
          }
        ] else [ ])
        ++ (if machine.staticIp6 != null then [
          {
            name = machine.staticIp6;
            value = [ "${machine.name}.endpoint.zebre.us" ];
          }
        ] else [ ])
        )
        (lib.attrValues config.machines));

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager =
        lib.mkIf config.networking.networkmanager.enable {
          unmanaged = [ "antibuilding" ];
        };

      # Configure the WireGuard interface.
      wireguard.interfaces = {
        # "antibuilding" is the network interface name.
        antibuilding = {
          ips = [ "${ipv6_prefix}::${builtins.toString thisMachine.address}/64" ];
          listenPort = 51820;

          # Path to the private key file.
          privateKeyFile = config.age.secrets.wireguard_private_key.path;

          peers = builtins.map
            (machine: (
              {
                name = machine.name;
                publicKey = machine.wireguardPublicKey;
                presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
                # Send keepalives every 25 seconds.
                persistentKeepalive = 25;
              } //
              (if !isServer machine then {
                allowedIPs = [ "${ipv6_prefix}::${builtins.toString machine.address}/128" ];
              } else {
                allowedIPs = [ "${ipv6_prefix}::0/64" ];

                # Set this to the server IP and port.
                endpoint = "${machine.name}.endpoint.zebre.us:51820";
                dynamicEndpointRefreshSeconds = 60;
              })
            ))
            otherMachines;

          # Setup firewall rules for the WireGuard interface.
          postSetup = builtins.concatStringsSep "\n" (
            if isServer thisMachine then
              [
                # Make sure the temp chain does not exist and is empty
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-input-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-input-temp || true"
                # Create the temp chain.
                "${pkgs.iptables}/bin/ip6tables -N antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -N antibuilding-input-temp || true" # The input chain should only contain drop rules
              ] ++
              ((builtins.concatMap
                (machine:
                  # Trusted machines are allowed to connect to all other machines.
                  (if machine.trusted then
                    [
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -s ${ipv6_prefix}::${builtins.toString machine.address} -j ACCEPT"
                    ] else [ ]) ++
                  # Block connections from untrusted machines, if this machine is not public.
                  (if machine.trusted || thisMachine.public then [ ] else [
                    "${pkgs.iptables}/bin/ip6tables -A antibuilding-input-temp -s ${ipv6_prefix}::${builtins.toString machine.address} -j DROP"
                  ]) ++
                  # Connections to public machines are allowed from all other machines.
                  (if machine.public then
                    [
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -d ${ipv6_prefix}::${builtins.toString machine.address} -j ACCEPT"
                    ] else [ ]))
                otherMachines) ++
              [
                "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -m state --state RELATED,ESTABLISHED -j ACCEPT"
                "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -j DROP"
                # Add the new chain
                "${pkgs.iptables}/bin/ip6tables -A FORWARD -j antibuilding-forward-temp"
                "${pkgs.iptables}/bin/ip6tables -I INPUT 1 -j antibuilding-input-temp"
                # Delete the previous chain
                "${pkgs.iptables}/bin/ip6tables -D FORWARD -j antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -D INPUT -j antibuilding-input || true"
                # Give the real name to the new chain
                "${pkgs.iptables}/bin/ip6tables -E antibuilding-forward-temp antibuilding-forward"
                "${pkgs.iptables}/bin/ip6tables -E antibuilding-input-temp antibuilding-input"
              ]) else [ ]
          );

          # Tear down firewall rules
          postShutdown = builtins.concatStringsSep "\n" (
            if isServer thisMachine then
              ([
                # Remove and delete the chains
                "${pkgs.iptables}/bin/ip6tables -D FORWARD -j antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -D INPUT -j antibuilding-input || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-input || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-input || true"
              ] ++ [
                # Do the same for the temp chains, if they exist (they should not, but just in case)
                "${pkgs.iptables}/bin/ip6tables -D FORWARD -j antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -D INPUT -j antibuilding-input-temp || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-input-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-input-temp || true"
              ]) else [ ]
          );
        };
      };
    };

    # Enable IP forwarding on the server so peers can communicate with each other.
    boot =
      if isServer thisMachine then {
        kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
      } else { };
  };
}
