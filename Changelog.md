# Tiny UI Fix for The Sims 3

## Changelog

### Version 1.5.1

#### User-facing

- An oversight which resulted in certain cursor scale values causing the script to fail to generate a package was fixed.
- Recommended patchsets are now enabled by default, in the configurator, during the first run.
- To ward confusion, the "Vanilla Core DLL Compatibility Patches" patchset now has a recommendation message in the configurator.

### Version 1.5.0

#### User-facing

- The Tiny UI Fix can now scale mouse cursors! (Most of them—not all.)
- Severe issues with scrolling at most non-integral UI scales have been fixed; the coordinates for grid and item-grid cells are now truncated to integers.
- The script is now significantly faster at scaling resources in packages.
- There is a new "Slider Enhancements" patchset, which enhances sliders in many various ways—mostly for CAS.
- The left/right side radio-buttons is CAS's Tattoos menu are no longer stretched.
- The Costume Makeup window in CAS is no longer too small when using NRaas Master Controller's CAS integration.
- Warnings are now logged with more context when finding resources across packages.
- The runtime mod mismatch check now examines a sampling of `STBL` resource-keys, to avoid most false negatives for script mods loaded not by an XML tuning but via other scripts.

### "Slider Enhancements" patchset
The "Slider Enhancements" patchset enhances sliders in the following ways:

- Right-clicking a slider will bring up a dialog that allows a numeric value to be typed in for the slider.
- When the mouse is over a slider, keyboard keys can be used to change its value, those keys are:
	- `A` to decrement the slider by 1.
	- `D` to increment the slider by 1.
	- `S` to decrement the slider by 8.
	- `W` to increment the slider by 8.
	- `F` to decrement the slider by 32.
	- `R` to increment the slider by 32.
	- `Shift`+`A` to decrement the slider by 64.
	- `Shift`+`D` to increment the slider by 64.
	- `Shift`+`S` to decrement the slider by 128.
	- `Shift`+`W` to increment the slider by 128.
	- `Shift`+`F` to decrement the slider by 256.
	- `Shift`+`R` to increment the slider by 256.
- In Create a Sim, this functionality is extended to apply to the last slider that the mouse was over—making it possible to change a slider while adjusting the camera.
- There are ten save-slots available for slider values, each corresponding to a number key on the keyboard. \
Pressing `Alt`+`<a number key>` will save the current value of a slider to the corresponding save slot. \
Pressing `<a number key>` will load a saved value from the corresponding save slot. \
\
The default values of the save-slots, from zero-to-ten, are: 0; -256; -128; 0; 128; 256; -64; 64; -32; 32. \
Shift+0 will reset all save-slots to their default value.
\
The behaviour for whether or not a slider is focussed is the same as for the keyboard keys for decrementing and incrementing a slider.
- In Create a Sim, slider values can be set beyond their usual limits via this functionality.

#### Developer-side

- Patchsets can now rewrite layouts before they are scaled, via the `BeforeUIScaling.SupplyLayoutTransformers` member.
- The package sources returned by `FindResourcesAcrossPackages` are now normalised, and returned resource keys are now all of the same type.
- `FindResourcesAcrossPackages` now supplies resource-index-entries to conditional filters, instead of only a resource-key.
- Images can now be scaled, via FFmpeg.
- Patchsets can now request that images be scaled, via the `DuringUIScaling.EnqueueScalingOfImages` member.
- The function that `Apply-ConvenientPatchesToAssemblies` uses to scale values is now parametrised.

### Version 1.4.3

#### User-facing

- The Build mode catalog grid should no longer have one too many columns.
- The Tiny UI Fix script is now slightly quicker at finding resources across packages.
- The runtime mod mismatch check now examines the resource-keys of only XML tuning and PNG UI image resources, to avoid introducing an excessive delay for entering the main menu. (For the author, this change reduced the delay from ~8.5-seconds to ~80-milliseconds).
This brings the possibility of not detecting non-script mods being uninstalled, but such is relatively harmless. Whereas, script mods will always have at-least one XML tuning resource, so there should be no chance of a false negative for script mods (which is where the real potential of harm lies).

### Version 1.4.2

#### User-facing

- The game's options menu no longer fails to scale when it is the first layout to be scaled (which could happen when a mod altered the options menu).

### Version 1.4.1

#### User-facing

- The checkboxes and radio-buttons in the game's options menu are no longer stretched. (The monkey's paw curl to this is that now the captions for those checkboxes and radio-buttons no longer contribute to their hit area, which is why they were stretched.)
- The script should no longer fail to generate a package when a Steam library lacks an `apps` key in Steam's `libraryfolders.vdf` file.
- A bug which caused the "The configurator is available at the URL:" message to be duplicated, instead of overwritten, when errors were logged, or when configurator's "Uninstall" button was used, has been fixed.

### Version 1.4.0

#### User-facing

- In previous versions of the mod, some users have encountered a bug wherein the game becomes unable to re-enter Live mode after entering Buy/Build mode. This seems to be caused by dismissal of the "Popular Store Items" notification (which appears after entering Buy/Build mode, if Shop Mode is enabled). To prevent this from happening, the mod now prevents those Store notifications from appearing at all. Given that those notifications are just ads for micro-transactions, their loss likely shan't be lamented.
- The script should now automatically detect EA App installations of the game on macOS.
- The mod now keeps track of which mods were installed and patched when the script was last run; when the game loads into the main-menu, the Tiny UI Fix checks if any patched mods have been removed or if any script mods have been added since the script was last run, and if such is the case, the mod displays a dialog warning that the script should be re-run to avoid errors. This check can be disabled via the configurator, should there be any annoying false-positives.
- A message is now displayed in the PowerShell console when the Tiny UI Fix is uninstalled via the configurator's "Uninstall" button.
- The configurator no longer fails to open, on macOS, when a port is already in use.
- A typo which caused the script to search for game packs in `./Applications/The Sims 3 Packs` instead of `/Applications/The Sims 3 Packs`, on macOS, has been corrected.
- A type which caused the configurator's "Uninstall" button to delete old v1.0.3-and-older-versions of the mod at `Overrides/tiny-tiny-ui-fix.package` instead of `Overrides/tiny-ui-fix.package` has been corrected.
- Typos which caused the configurator's configuration value inputs to be incorrectly justified have been corrected. 

#### Developer-side

- Warning-promoted-to-error `NU1605` should no longer prevent `Mono.Cecil` from building.
- `ReactToInitialisationOfMainMenu` has been moved from the `WindowAttachmentHooks` class to a new `MainMenuHooks` class.
- Some stray debugging code was removed from `TinyUIFixForTS3Patcher.cs`.

### Version 1.3.4

#### User-facing

- The script should now be more likely to find installations of the game on macOS.
- The 32-bit version of the macOS version of the game is now supported.
- The script can now automatically detect the Steam version of the game.
- The script is now able to find resources from game packs (that is, expansion packs and stuff packs).
- The script is now able to determine which locales are configured for use by the game and by the game packs.
- The script now has functionality for uninstalling the Tiny UI Fix. This can be used via the "Uninstall" action in the configurator, or via the `Uninstall` command-line switch.
- The logic for downloading files from alternative URLs, should the download from the primary URL fail, has been fixed.
- The alternative URLs for downloading S3PI by Peter Jones, and 7-zip by Igor Pavlov, have been fixed.
- The auto-completion for the `PatchsetLoadOrder` parameter no longer sets the `$Global:CommandAST` variable.
- The error logging for patchsets that failed to load has been fixed.

#### Developer-side

- Unpatched resources are now categorised by patchset.
- `Find-InstanceProperty` and `Find-StaticProperty` now actually differentiate between static and instance properties.
- Calling `StartWriting` in the context of `Edit-MethodBody` no longer needlessly reassigns the `StartOfIL`, `Instruction`, and `Returns` variables.
- The `AfterUIScaling` members for patchsets are no longer supported. (They're unused, anyway). This is because they make it difficult for patchsets to act harmoniously.
- When the patchset definition schema version is at-least 2, the `MakeDefaultConfiguration` patchset member now receives an argument for the `State` parameter.
- The `Tools/Update-VersionNumber.ps1` script now updates the `AssemblyVersion` numbers in addition to the `AssemblyFileVersion` numbers.
- The `Tools/Invoke-OpenSesame.ps1` script now correctly resolves relative paths that are supplied as strings.
- The `InstructionPatching.ReplaceBranchTargetsIn` method now updates the branch targets of `switch` statements.

### Version 1.3.3

#### User-facing

- The `tiny-ui-fix-for-ts3.command` file in the `tiny-ui-fix-for-ts3.command.zip` download for macOS is now executable by default when the zip is extracted by Safari instead of by Finder.
- The `tiny-ui-fix-for-ts3.command` script no longer fails on systems that already have PowerShell installed.

#### Developer-side

- The `BadZipArchiveAPIWorkaroundStream` class now has some protection against its slim possibility of corrupting zip files.

### Version 1.3.2

#### User-facing

- To improve mod compatibility, the layout-scaler is now more tolerant of expected XML nodes being absent.
- To improve the usability of patchset load-order auto-completion in PowerShell 5.1, `*` will now auto-complete to all available patchsets.
- When checking for updates, "ModTheSims" is now "Mod The Sims".

### Version 1.3.1

#### User-facing

- The `tiny-ui-fix-for-ts3.command` file in the `tiny-ui-fix-for-ts3.command.zip` download for macOS is now executable by default when extracted by Finder on macOS 10.15-and-later (10.15 is macOS Catalina).
- Links now look a bit nicer in the configurator.
- When an update is available, the "Check for updates" button in the configurator will now link to the Mod The Sims listing for the Tiny UI Fix, in addition to its GitHub repository.

#### Developer-side

- The implementation for setting file-permissions in a zip-archive using only the standard-library is comical, give it a peek in `Building/Package-SingleFileDistributables.ps1`.

### Version 1.3.0

#### User-facing

- The generated `tiny-ui-fix.package` file will now function correctly when it is generated on a system with a locale that does not use dots for decimal-points.
- A compatibility patchset is now included for LazyDuchess's Smooth Patch package.
- Recommended patchsets are now listed before other patchsets in the configurator. (Excluding the Nucleus and Vanilla Core DLL Compatibility Patches patchsets, which always come first).
- There is now command-line argument-completion for the `PatchsetLoadOrder` parameter of the `Use-TinyUIFixForTS3.ps1` script.
- A bug which caused an error to occur when an error was logged from outside the context of a catch statement was fixed. (Non-lexical scoping is great until it's not.)

#### Developer-side

- The `Apply-ConvenientPatchesToAssemblies` function can now scale doubles.

### Version 1.2.2

#### User-facing

- An error caused by the invalid XML error handling, introduced by version 1.2.1, was fixed.
- Errors that occur during layout scaling are now logged with more detail.

### Version 1.2.1

#### User-facing

- Errors are now printed with more detail, to make troubleshooting easier.
- Errors caused by XML resources consisting of invalid XML are now handled more gracefully—the offending XML resources are skipped.

### Version 1.2.0

#### User-facing

- In some circumstances, S3SA resources with the lowest priority would be included in the generated `tiny-ui-fix.package` file, instead of the resources with the highest priority.
This has been fixed to correctly use the resources with the highest priority. \
As a consequence of this, the Tiny UI Fix should no longer be incompatible with simler90's Gameplay Core Mod.

### Version 1.1.1

#### User-facing

- On Windows, if the "Controlled folder access" setting is enabled and is preventing the script from writing to the user-data folder of the Sims 3 installation that's being scaled, then the script will offer to temporarily allow PowerShell to access controlled folders.

### Version 1.1.0

#### User-facing

- The Tiny UI Fix no longer conflicts with the usage of CC Magic—the script now has the ability to edit the settings of CC Magic to ensure that the package generated by the Tiny UI Fix is always loaded. \
And, `Resource.cfg` files that have been edited by CC Magic can now be correctly processed by the Tiny UI Fix; see the next entry of this list for more detail on that.
- Evaluation of `Resource.cfg` files is now more accurate to how the game processes such files. \
Previously, only the `Priority` and `PackedFile` directives were recognised, and only a subset of their possible usage was recognised. With this update, the `Priority`, `PackedFile`, `DirectoryFiles`, `Scan`, and `StopScan` directives are recognised; additionally, quoted directive operands are now recognised, as are directives with comma-separated arguments following their operands. Nested `Resource.cfg` files that are implicitly referenced via a `PackedFile` or `DirectoryFiles` directive are also evaluated.
- `Use-TinyUIFixForTS3.ps1` now has two parameters which can be used to override the paths for the installation of The Sims 3 that's being patched, they are: `OverrideSims3Path` and `OverrideSims3UserDataPath`. The primary purpose of these parameters is to enable non-interactive usage of the script on platforms other than Windows and macOS.
- The game's text can now be scaled independently of the game's UI. (As suggested by u/U_Cam_Sim_It on Reddit).

#### Developer-side

- The `Tools/Update-VersionNumber.ps1` script now updates the version numbers of the `TinyUIFixForTS3` and `TinyUIFixForTS3CoreBridge` assemblies.

### Version 1.0.5

#### User-facing

- Layout and text-style scaling no longer fails when the system-locale does not use a dot for decimal-points.

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
