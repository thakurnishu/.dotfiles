# macOS system defaults — Phase 2.
#
# Everything declared here is re-applied on every `darwin-rebuild switch`.
# If you change one of these by hand in System Settings, the next rebuild
# silently puts it back. That is the point, but it surprises people once.
# To take a setting back under manual control, delete its line here.
{ ... }:
{
  system.defaults = {

    # ---- Tiling window manager essentials --------------------------------
    spaces = {
      # Turns OFF System Settings -> Desktop & Dock -> "Displays have
      # separate Spaces". AeroSpace needs this for multi-monitor to behave.
      # Previously a manual step; now declared.
      # NOTE: macOS requires a logout/login for this one to take effect.
      spans-displays = true;
    };

    dock = {
      # Stop macOS reordering Spaces by most-recent-use. Reordering happens
      # behind AeroSpace's back and desynchronises its workspace model.
      mru-spaces = false;

      # Hide until the pointer reaches the bottom edge. Nothing is removed.
      autohide = true;

      # Stop appending recently-used apps to the end of the Dock.
      show-recents = false;
    };

    # ---- Keyboard --------------------------------------------------------
    NSGlobalDomain = {
      # Hide the menu bar until the pointer reaches the top edge. The bar
      # and everything in it (clock, battery, AeroSpace's workspace number)
      # still exist and return on hover — this hides, it does not remove.
      _HIHideMenuBar = true;

      # Faster than the System Settings sliders allow (their floor is 15/25).
      KeyRepeat = 2; # delay between repeats
      InitialKeyRepeat = 15; # delay before repeating starts

      # Disable the accent-character popup on key hold. That popup blocks
      # holding j/k/h/l to scroll in nvim.
      ApplePressAndHoldEnabled = false;
    };

    # ---- Finder ----------------------------------------------------------
    finder = {
      # macOS hides extensions by default: screenshot.png shows as
      # "screenshot". Turn that off.
      AppleShowAllExtensions = true;

      ShowPathbar = true; # breadcrumbs at window bottom
      ShowStatusBar = true; # item count + free space

      # Search the current folder first rather than the whole Mac.
      FXDefaultSearchScope = "SCcf";

      _FXSortFoldersFirst = true;
    };
  };

  # ---- DNS ----------------------------------------------------------------
  # Cloudflare rather than whatever DHCP hands out. The ISP resolvers
  # (218.248.114.117 / 218.248.90.117) were caching negative answers well past
  # their usefulness: a Route53 record confirmed live -- and resolving from
  # both Route53's own nameservers and 8.8.8.8 -- kept returning NXDOMAIN
  # locally for a while after creation. That bites every time external-dns
  # creates a hostname for a Gateway/HTTPRoute and you try to reach it.
  #
  # nix-darwin runs `networksetup -setdnsservers <service> <dns...>` on every
  # activation, so this is not a one-off that a later rebuild reverts -- the
  # rebuild is what reasserts it. Survives reboots because it is stored in the
  # network service itself, not in a running resolver.
  #
  # 1.0.0.1 is the secondary, not a fallback to the ISP: macOS treats the list
  # as a set to race, so leaving an ISP address in it would keep serving the
  # stale answers this is meant to avoid.
  #
  # Every service is listed because DNS is per-service on macOS -- setting only
  # Wi-Fi would silently go back to the ISP the moment the LAN adapter is
  # plugged in. Names must match `networksetup -listallnetworkservices`
  # exactly; the module skips any that is not present, so an absent adapter is
  # harmless rather than an activation failure.
  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1G/2.5G LAN"
    "Thunderbolt Bridge"
  ];
  networking.dns = [ "1.1.1.1" "1.0.0.1" ];

  # Not declared, left under manual control:
  #   screencapture.location — macOS Cmd-Shift-3/4 keeps writing to Desktop.
  #     (Your alt-shift-p binding is clipboard-only and writes no file.)
}
