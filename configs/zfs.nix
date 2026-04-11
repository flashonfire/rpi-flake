{ ... }:
{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "storage" ];
  boot.zfs.devNodes = "/dev/disk/by-id";

  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  networking.hostId = "44cadff6";

  services.zfs.zed = {
    enableMail = true;
    settings = {
      ZED_EMAIL_ADDR = [ "guillaume.calderon1313@gmail.com" ];
      ZED_EMAIL_PROG = "/run/current-system/sw/bin/msmtp";
      ZED_EMAIL_OPTS = "@ADDRESS@";
      ZED_NOTIFY_INTERVAL_SECS = 10;
      ZED_NOTIFY_VERBOSE = true; # notify on scrub success too, not just failures
      ZED_NOTIFY_DATA = true; # include zpool status in mail body
    };
  };

  boot.extraModprobeConfig = ''
    options zfs zfs_vdev_sync_read_max_active=1
    options zfs zfs_vdev_sync_write_max_active=1
    options zfs zfs_vdev_sync_read_min_active=1
    options zfs zfs_vdev_sync_write_min_active=1
    options zfs zfs_vdev_async_read_max_active=1
    options zfs zfs_vdev_async_write_max_active=1
    options zfs zfs_vdev_async_read_min_active=1
    options zfs zfs_vdev_async_write_min_active=1
    options zfs zfs_vdev_max_active=8
    options zfs zfs_txg_timeout=5
    options zfs zfs_dirty_data_max=67108864
    options zfs zfs_arc_max=2147483648
  '';
}
