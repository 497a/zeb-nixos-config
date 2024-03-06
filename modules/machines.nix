# Option definitions for information about the machines in the network
{ lib, ... }:
with lib;
let
  machineOpts = self: {
    options = {
      name = mkOption {
        example = "bernd";
        type = types.str;
        description = lib.mdDoc "Hostname of a machine on the network";
      };

      wireguardPublicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.singleLineStr;
        description = lib.mdDoc "The base64 wireguard public key of the machine.";
      };

      address = mkOption {
        example = 6;
        type = lib.types.ints.between 1 255;
        description = lib.mdDoc ''The last byte of the antibuilding IPv4 address of the machine.'';
      };

      staticIp6 = mkOption {
        example = "1111:1111:1111:1111::1";
        type = types.nullOr types.str;
        description = lib.mdDoc ''A static ipv6 address where this machine can be reached.'';
        default = null;
      };

      staticIp4 = mkOption {
        example = "10.192.122.3";
        type = types.nullOr types.str;
        description = lib.mdDoc ''A static ipv4 address where this machine can be reached.'';
        default = null;
      };

      trusted = mkOption {
        example = true;
        type = types.bool;
        description = lib.mdDoc ''Whether this machine is allowed to access all other machines in the VPN.'';
        default = false;
      };

      public = mkOption {
        example = true;
        type = types.bool;
        description = lib.mdDoc ''Whether this machine can be accessed by untrusted machines in the VPN.'';
        default = false;
      };

      sshPublicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.nullOr types.singleLineStr;
        description = lib.mdDoc "The public SSH host key of this machine. Implies that the machine can be accessed via SSH.";
        default = null;
      };
    };

  };
in
{
  options = {
    machines = mkOption {
      default = [ ];
      description = lib.mdDoc "Information about the machines in the network";
      type = with types; attrsOf (submodule machineOpts);
    };
  };
}
