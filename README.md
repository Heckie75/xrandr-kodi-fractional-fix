# xrandr-kodi-fractional-fix

A lightweight Shell script fix for **Kodi fullscreen display bugs** under Linux desktop environments using **X11 Fractional Scaling** (such as Linux Mint Cinnamon).

## The Problem
When using fractional scaling (e.g., 125% or 150%) on a 4K display under X11/Cinnamon, the window manager scales the virtual framebuffer up (e.g., to `6144x3456`). 

When Kodi switches to fullscreen mode, it queries `xrandr` and attempts to render using these padded framebuffer bounds. As a result:
* Kodi only fills **a quarter of the screen** (bottom-left or top-left quadrant).
* Software rendering fallbacks occur, leading to **severe stuttering / laggy 4K playback** due to missing hardware acceleration alignment.

## The Solution
This script automatically detects your active primary monitor, reads its current XRandR transformation matrix (fractional scaling factor), and explicitly sets the correct `--panning` geometry to match the physical resolution.

Instead of wrapping Kodi or toggling system desktop settings back and forth, you simply run this script once at the start of your X session or autostart.

## Features
* **Dynamic detection:** Automatically identifies the primary display, native mode resolution, and active fractional scale factor.
* **Fail-safe:** Aborts cleanly without modifying display properties if display metrics cannot be reliably parsed.
* **Locale-aware:** Safely parses floating-point scale matrices across localized desktop environments (`LC_NUMERIC=C`).

## Installation & Usage

### Prerequisites
* `xrandr` must be installed and available in your `$PATH`.
* This script is intended for X11 sessions only, not Wayland.
* Run it in the same display/session that launches Kodi.

1. **Clone or download this repository:**
   ```bash
   git clone https://github.com/your-username/xrandr-kodi-fractional-fix.git
   cd xrandr-kodi-fractional-fix
   ```
2. **Make the script executable:**
   ```bash
   chmod +x fix_kodi_resolution.sh
   ```

3. **Test the script:**
   ```bash
   ./fix_kodi_resolution.sh
   ```
   The output should look like this:
   ```bash
   Monitor:            DP-3
   Native Resolution:  3840x2160
   Current Scale:      1.60x1.60
   ```

4. **Optional dry run:**
   ```bash
   ./fix_kodi_resolution.sh --dry-run
   ```

5. **Reset the fix:**
   ```bash
   ./fix_kodi_resolution.sh --reset
   ```
   Use this after closing Kodi or before launching Wine if you need to restore normal X11 panning.

6. **Add to Startup Applications:**
* Open Startup Applications in your desktop settings (e.g., Linux Mint Cinnamon Menu -> Startup Applications).
* Add a new custom command pointing to the absolute path of `fix_kodi_resolution.sh`.
* Use a command like:
   ```bash
   /home/your-user/bin/xrandr-kodi-fractional-fix/fix_kodi_resolution.sh
   ```
* Set a small delay (2–3 seconds) to ensure the display manager has finished initializing.

> Note: If you change the fractional scaling factor after login, you must rerun this script so Kodi receives the updated panning settings.
>
> **Warning:** This script changes the X11 panning viewport. Wine applications may stop refreshing correctly outside the panned region while the fix is active. If you use Wine, apply the fix only before launching Kodi and reset it afterward.

## Compatibility
Tested and confirmed working on:

* OS: Linux Mint 21.x / 22.x
* Desktop Environment: Cinnamon (X11)
* Hardware: 4K UHD monitors with 125% / 150% fractional scaling
* Target application: Kodi Media Center v19+

## Troubleshooting
* If the script reports "No active monitor found", verify you are running under X11 and that `xrandr --current` shows a connected output.
* If the scale factor cannot be parsed, run `xrandr --current --verbose` and inspect the `Transform:` values for your active monitor.
* Use `./fix_kodi_resolution.sh --dry-run` to confirm the generated xrandr command before applying it.
* If Wine applications stop updating correctly after applying the fix, run `./fix_kodi_resolution.sh --reset` to restore normal X11 panning before launching Wine.

## License
MIT License - feel free to modify and share!