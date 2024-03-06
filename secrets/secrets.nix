with import ./public-keys.nix;
{
  # SSH host keys
  # The ed25519 keys are also used for agenix
  # 
  # Can be decrypted by recovery key and self
  # Storing the public keys in here is redundant, but it makes it easier to deploy them
  #
  # Generated with `nix run .#gen-host-keys`
  "erms_ed25519.age".publicKeys = [ recovery erms ];
  "erms_ed25519_pub.age".publicKeys = [ recovery erms ];
  "erms_rsa.age".publicKeys = [ recovery erms ];
  "erms_rsa_pub.age".publicKeys = [ recovery erms ];
  "kashenblade_ed25519.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_ed25519_pub.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa_pub.age".publicKeys = [ recovery kashenblade ];
  "kappril_ed25519.age".publicKeys = [ recovery kappril ];
  "kappril_ed25519_pub.age".publicKeys = [ recovery kappril ];
  "kappril_rsa.age".publicKeys = [ recovery kappril ];
  "kappril_rsa_pub.age".publicKeys = [ recovery kappril ];
  # MARKER_HOST_KEYS

  # Private user keys
  # Can be decrypted by recovery key, hosts where the user is required, and self
  # These keys should be password protected
  "lennart_ed25519.age".publicKeys = [ recovery erms lennart ];
  "lennart_ed25519_pub.age".publicKeys = [ recovery erms lennart ];

  # Wireguard keys
  # Can be decrypted by recovery key or the respective machine key
  # Generated with `nix run .#gen-wireguard-keys`
  "erms_wireguard.age".publicKeys = [ recovery erms ];
  "erms_wireguard_pub.age".publicKeys = [ recovery erms ];
  "kashenblade_wireguard.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_wireguard_pub.age".publicKeys = [ recovery kashenblade ];
  "kappril_wireguard.age".publicKeys = [ recovery kappril ];
  "kappril_wireguard_pub.age".publicKeys = [ recovery kappril ];
  "tick_wireguard.age".publicKeys = [ recovery tick ];
  "tick_wireguard_pub.age".publicKeys = [ recovery tick ];
  # MARKER_WIREGUARD_KEYS

  "shared_wireguard_psk.age".publicKeys = [ recovery erms kashenblade kappril tick ];

  # Backup secrets
  # For now this is keyed to the machine where the backup is initiated from, but it would make more sense to key it to lennart
  # Generated with `tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo`
  "lennart_backup_passphrase.age".publicKeys = [ recovery erms lennart ];
  "matrix_backup_passphrase.age".publicKeys = [ recovery kashenblade lennart ];
  # MARKER_BORG_PASSPHRASES

  # Backup keys
  # These keys are used to connect to borg instances
  # The append_only keys dont have a passphrase, but can only access the backup repository in append-only mode
  # The trusted keys also dont have a passphrase and can access the backup repository in read-write mode. However they can only be decrypted by a password protected user key
  "lennart_backup_append_only_ed25519.age".publicKeys = [ recovery erms lennart ];
  "lennart_backup_append_only_ed25519_pub.age".publicKeys = [ recovery erms lennart ];
  "lennart_backup_trusted_ed25519.age".publicKeys = [ recovery lennart ];
  "lennart_backup_trusted_ed25519_pub.age".publicKeys = [ recovery lennart ];
  "matrix_backup_append_only_ed25519.age".publicKeys = [ recovery kashenblade lennart ];
  "matrix_backup_append_only_ed25519_pub.age".publicKeys = [ recovery kashenblade lennart ];
  "matrix_backup_trusted_ed25519.age".publicKeys = [ recovery lennart ];
  "matrix_backup_trusted_ed25519_pub.age".publicKeys = [ recovery lennart ];
  # MARKER_BORG_BACKUP_KEYS

  # This is secret because it contains information about the infrastructure of other people
  "extra_config.age".publicKeys = [ recovery erms lennart ];

  # Shared secret for coturn.
  # Matrix does not support a file option, but can load extra config files, so we use a config file that only sets the secret
  "coturn_static_auth_secret.age".publicKeys = [ recovery kashenblade ];
  "coturn_static_auth_secret_matrix_config.age".publicKeys = [ recovery kashenblade ];
}
