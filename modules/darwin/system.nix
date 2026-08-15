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

  # Not declared, left under manual control:
  #   screencapture.location — macOS Cmd-Shift-3/4 keeps writing to Desktop.
  #     (Your alt-shift-p binding is clipboard-only and writes no file.)
}
