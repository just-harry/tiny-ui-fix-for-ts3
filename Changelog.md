# Tiny UI Fix for The Sims 3

## Changelog

### Version 1.0.4

#### User-facing

- There is now a button, in the configurator, for checking for updates to the Tiny UI Fix.
- The generated `tiny-ui-fix.package` is now saved to `Mods/TinyUIFix/tiny-ui-fix.package` instead of `Mods/Overrides/tiny-ui-fix.package`, to ensure that the Tiny UI Fix package is loaded after the packages that it scales. The script will automatically add an entry to the `Resource.cfg` file to set-up a priority for the package—if a `Resource.cfg` file does not exist, one will be created. Old `tiny-ui-fix.package` files in `Mods/Overrides/tiny-ui-fix.package` will be deleted automatically, so there's no need to worry about cleaning them up manually.
- The version of the Tiny UI Fix script is now printed on start-up.
- The version of a patchset is now logged alongside its ID.
- The assembly names of all the assemblies that are initially resolved are now printed. Hopefully, this should help to diagnose patchsets failing to identify assemblies by name.
- Mod folders containing exactly one package file no longer cause an `Unable to index into an object of type System.Collections.Generic.Dictionary`2[System.UInt64,System.Collections.Generic.IEnumerable`1[System.Object]]` error to occur.
- Errors that occur when a layout is being scaled are now handled gracefully: the layout is skipped, and the resource-key and the package of the layout is logged.

#### Developer-side

- The `Building/Build-All.ps1` script no longer fails on the first build, as the core-bridge is now correctly built before the patch and patcher.
- There is now a `Tools/Update-VersionNumber.ps1` script to update the version number of the Tiny UI Fix script in all the places it should be updated in.

### Version 1.0.3

- A regression introduced by version 1.0.2, which caused the `Apply-ConvenientPatchesToAssemblies` function to fail to scale the descendant fields of field-chains starting with an instance field was fixed.
- As a result of the fix to `Apply-ConvenientPatchesToAssemblies`, interaction-queue items are once again scaled properly.

### Version 1.0.2

- The `Apply-ConvenientPatchesToAssemblies` function is now capable of scaling the descendant fields of fields loaded by-reference (via the `ldsflda` and `ldflda` op-codes), so long as the terminal field is loaded by-value and the field loaded by-reference isn't of an array type.
- As a result of the enhancement to `Apply-ConvenientPatchesToAssemblies`, the methods for the enhanced family-tree dialog added by NRaas Master Controller are now patched correctly by the `CompatibilityPatchesForNRaasMods` patchset, resulting in the game no longer freezing when that dialog is opened. (Thanks to u/U_Cam_Sim_It on Reddit for the bug-report).
- The graphics that display on the screen when taking a photo are no longer incorrectly positioned. (Thanks to u/nubyplays on Reddit for the bug-report).
- The `Package-SingleFileDistributables.ps1` script now emits a zipped version of the Batch file for Windows which can be run successfully when it's opened within Windows Explorer (in preparation for the archive that will be submitted to Mod The Sims).
- Some informatory warnings are printed when an installation of The Sims 3 doesn't seem to have been set-up for modding.

### Version 1.0.1

* A failed attempt to fix a glitch that caused the game to freeze when an NRaas Master Controller enhanced family-tree dialog was opened, even when the `CompatibilityPatchesForNRaasMods` patchset was active, was attempted.
