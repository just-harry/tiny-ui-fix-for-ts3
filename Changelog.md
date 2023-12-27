# Tiny UI Fix for The Sims 3

## Changelog

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
