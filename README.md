# Ultimate Mouse Cursor 3.3.5a Backport

Backport of Ultimate Mouse Cursor for WoW 3.3.5a / Wrath clients.

## Target client

World of Warcraft 3.3.5a / Interface 30300.

## Download

Use the attached release asset:

```text
UltimateMouseCursor-3.3.5a-backport-r6.zip
```

Do not use GitHub's automatic "Source code (zip)" download.

## Install

1. Delete or move any older `UltimateMouseCursor` folder from `Interface\AddOns`.
2. Extract the zip so the final path is:

   ```text
   World of Warcraft\Interface\AddOns\UltimateMouseCursor\UltimateMouseCursor.toc
   ```

3. Optional but recommended: keep `!!!ClassicAPI` installed/enabled. This backport declares it as an `OptionalDep` and will use its modern widget/API shims when available.

   ```text
   World of Warcraft\Interface\AddOns\!!!ClassicAPI
   ```

4. Start the game and enable "Load out of date AddOns" if your client requires it.
5. Use `/umc` or `/ultimate` to open options.

## Backport changes

- TOC changed to Interface 30300 and `OptionalDeps: !!!ClassicAPI`.
- Added `UMC_Compat_335.lua` for 3.3.5a-safe shims/fallbacks:
  - `C_ClassColor.GetClassColor`
  - `C_Spell.GetSpellCooldown`
  - `Texture:SetAtlas` / `Texture:SetColorTexture` fallbacks
  - Cooldown widget `SetSwipeTexture` / `SetSwipeColor` / `SetReverse` / `SetRotation` / etc. fallbacks
  - `ColorPickerFrame:SetupColorPickerAndShow` fallback
  - `Slider:SetObeyStepOnDrag` fallback
  - `UnitPower` / `UnitPowerMax` fallback guards
- Replaced modern XML `parentKey` texture references with 3.3.5a-safe named textures.
- Fixed 3.3.5a `UnitCastingInfo` / `UnitChannelInfo` return-position differences.
- Added legacy power event registration support for `UNIT_MANA`, `UNIT_RAGE`, `UNIT_ENERGY`, `UNIT_RUNIC_POWER`, etc.
- Added GCD fallback behavior when spell `61304` is unavailable on a server/core.
- Added load-order and nil guards around settings, reticle, crosshair, and frame setup.
- Renamed the retail-only "Fixed when Dragonriding" option in the UI to "Fixed while mounted/flying" while keeping the saved variable value compatible.

## Known limitations

- The modern atlas reticle choices are approximated with bundled dot/circle textures on a pure 3.3.5a client. With ClassicAPI installed, any atlas support it provides will be used.
- If your ClassicAPI build does not implement radial cooldown swipe textures, the addon will still load, but cast/GCD visuals may degrade to static/fallback cooldown visuals.
- This could not be run inside a live 3.3.5a client here, so please send any BugSack/Swatter error text if your server/client build exposes a different API behavior.

## Release notes

### r6 GCD timing note

- GCD duration is taken from `GetSpellCooldown(61304)` whenever available.
- `ACTIONBAR_UPDATE_COOLDOWN` is now used as an additional signal before falling back, so haste/reduced-GCD values have more time to populate.
- The static 1.5s fallback is only used after a short retry window when neither the dummy GCD spell nor the fired spell reports a short GCD-like cooldown.

### r5 notes

- Keeps the r3 baseline/trail behavior.
- Uses a Wrath-safe ArcAtlas renderer for active GCD/cast rings instead of ClassicAPI CooldownCapture.
- This avoids quadrant handoff jank around the 50%-75% castbar range.
- Active GCD/cast timing now uses exact durations instead of ClassicAPI's action-button cooldown padding.
- Successful casts show their final arc state for a very short finish frame to avoid looking like the ring ends early at low FPS.

### r3 changes

- Wrapped each ClassicAPI-powered cooldown in its own sized parent frame. ClassicAPI attaches custom swipe textures to the cooldown's parent, so this prevents zero-size/NaN TexCoord calculations and keeps GCD/cast rings concentric at their configured 50/70/90 sizes.
- Added extra cooldown-size repair before/after showing cooldown widgets.
- Moved cursor trail textures to a dedicated high-strata trail frame so the trail is not hidden behind the world/UI parent layers after setup errors.
- Added a short cast-info retry for the first cast/channel after login or reload.
- Added a GCD fallback on `UNIT_SPELLCAST_SUCCEEDED` / `CHANNEL_START` to reduce first-use lag when spell `61304` has not populated yet on a 3.3.5a core.

### r2 changes

- Fixed Wrath `UIDropDownMenu` errors by naming every dropdown frame used with `UIDropDownMenu_SetWidth` / `SetText`.
- Replaced `Texture:SetScale()` reticle scaling with width/height resizing, because 3.3.5a texture regions do not provide `SetScale()`.
- Moved `UMC_Compat_335.lua` before the main Lua file in the TOC for safer helper availability.
- Added a short GCD retry window and registered `UNIT_SPELLCAST_SUCCEEDED` / `START` for GCD tracking so instant spells on 3.3.5a do not get missed when `UNIT_SPELLCAST_SENT` fires before spell `61304` updates.
