{
  ...
}:

{
  services.crowdsec = {
    enable = true;

    # Read Caddy logs from files
    localConfig.acquisitions = [
      {
        source = "file";
        filenames = [ "/var/log/caddy/*.log" ];
        labels.type = "caddy";
      }
    ];
  };

  # Leaving the bouncer disabled effectively puts CrowdSec in "Report-Only" mode.
  # It will detect and log malicious IPs (viewable via `cscli alerts list`), but won't block them at the firewall.
  # Change `enable = false;` to `true` when you are ready to enforce blocks.
  services.crowdsec-firewall-bouncer = {
    enable = false;
  };
}
