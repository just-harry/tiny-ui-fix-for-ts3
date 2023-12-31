# Tiny UI Fix for The Sims 3

Tiny UI Fix is a UI scaling and fixing mod for The Sims 3.
It is distributed as a script that can generate a mod which scales the UI of The Sims 3 by an arbitrary multiplier.

## Installation

Tiny UI Fix for TS3 is a PowerShell script, but it is also distributed as a Batch file and Shell script for easy usage on Windows and macOS respectively.
<details>
<summary>

### On Windows
(press to expand)
</summary>

#### Prerequisites

On Windows 10, and later: there are no prerequisites. \
Otherwise, on previous versions of Windows: [at-least version 4.7.1 of the .NET Framework](https://support.microsoft.com/topic/the-net-framework-4-7-1-offline-installer-for-windows-2a7d0d5e-92f2-b12d-aed4-4f5d14c8ef0c), and [version 5.1 of PowerShell](https://learn.microsoft.com/powershell/scripting/windows-powershell/wmf/setup/install-configure?view=powershell-5.1).

#### Step-by-step

1. Download the patch's Batch file, `tiny-ui-fix-for-ts3.bat`, from [https://github.com/just-harry/tiny-ui-fix-for-ts3/releases/download/v1.1.0/tiny-ui-fix-for-ts3.bat](https://github.com/just-harry/tiny-ui-fix-for-ts3/releases/download/v1.1.0/tiny-ui-fix-for-ts3.bat).
2. Run the downloaded Batch file by double-clicking it.
3. Follow the instructions provided by the script.
</details>
<details>
<summary>

### On macOS
(press to expand)
</summary>

#### Prerequisites

At-least version 10.13 of macOS (version 10.13 is High Sierra).

#### Step-by-step

1. Download the zip containing the patch's Shell script, `tiny-ui-fix-for-ts3.command.zip`, from [https://github.com/just-harry/tiny-ui-fix-for-ts3/releases/download/v1.1.0/tiny-ui-fix-for-ts3.command.zip](https://github.com/just-harry/tiny-ui-fix-for-ts3/releases/download/v1.1.0/tiny-ui-fix-for-ts3.command.zip).
2. Open the downloaded zip file by double-clicking it. (The Safari browser may automatically take the script out of the zip file).
3. Right-click the `tiny-ui-fix-for-ts3.command` file and select "Open".
4. Select "Open" in the dialog that pops up.
5. If PowerShell is not installed on your Mac, the Shell script will ask if you would like to download PowerShell: when it does so, type in "y" for yes and press enter.
6. Follow the instructions provided by the script.
</details>
<details>
<summary>

### Advanced installation
</summary>

#### Prerequisites

Version 5.1 of PowerShell, or version 7.0-or-later of PowerShell.

The PowerShell script and its accompanying files can be downloaded as a zip-archive from [https://github.com/just-harry/tiny-ui-fix-for-ts3/releases/download/v1.1.0/tiny-ui-fix-for-ts3.zip](https://github.com/just-harry/tiny-ui-fix-for-ts3/releases/download/v1.1.0/tiny-ui-fix-for-ts3.zip). \
Extract that zip-archive to a directory, and then run the script in PowerShell via the `Use-TinyUIFixForTS3.ps1` file at the root of the directory.
</details>

## Animated UI scale comparison at 4K

https://github.com/just-harry/tiny-ui-fix-for-ts3/assets/12306246/7aeed898-2173-4432-a121-6adcc0c11c72

## Usage

Unlike a conventional mod for The Sims 3, Tiny UI Fix is not distributed as a package, instead it is distributed as a script which will generate a package—named `tiny-ui-fix.package`—specifically tailored for your installation of the game and your other active mods.
Because of this, the script should be run again when core mods and mods that affect the UI are added or removed from your installation of the game.

After the script is started, the script is configured through a web-browser using the configurator, usually the configurator can be found at [http://127.0.0.1:49603](http://127.0.0.1:49603/), but you can press enter when the script prompts you to to open the configurator.

The script prompting you to start the configurator:
![configurator-prompt](https://github.com/just-harry/tiny-ui-fix-for-ts3/assets/12306246/8fab41c5-db33-42b3-808a-9a4d193d919a)

What the configurator looks like:
![configurator-screen](https://github.com/just-harry/tiny-ui-fix-for-ts3/assets/12306246/28212569-a74e-4718-a8c1-c6077ceabe55)

The configurator is used as follows: \
At the left, we have the "Configuration" panel, this is used to configure the active patchsets.

At the moment there are two options: \
**UI Scale**: which is a multiplier which controls how big the game's UI is.
A value of one would keep the UI the same size as it normally is, whereas a value of two would make the UI twice as big as usual. \
**Text Scale**: which is a multiplier which controls how big the game's text is; by default, this is the same as the UI Scale. \
This is independent of the UI Scale, so if the Text Scale is set to be much larger than the UI Scale: text may overlap other elements of the UI.

---

Moving towards the right, we have the "Active Patchsets" panel, this is used to browse and enable/disable which patchsets are being used for the UI scaling.

A patchset is a bundle of patches that the Tiny UI Fix can apply when it scales the UI, they are effectively mods for the Tiny UI Fix.
Additional patchsets (if they are available) can be placed in the "Patchsets" folder of the "tiny-ui-fix-for-ts3" folder that the script resides in.

Every patchset is uniquely identified by an ID.

If you are a mod author, and you want to make someone else's mod compatible with the Tiny UI Fix: a patchset may be the easiest/least-disruptive way to do so.

---

Moving again to the right, we have the "Patchset Load-order" panel, this is used to control the order in which the Tiny UI Fix applies the patchsets; patchsets with a lower position-number are applied before patchsets with a higher position-number.
Generally, the patchset load-order doesn't matter unless two-or-more patchsets conflict with one another (such as if they applied patches to the same thing).

---

Lastly, we're now at the rightmost panel, which is the "Actions" panel, this is used to get the Tiny UI Fix to actually do something. \
"**Generate package**" will make the script start generating the `tiny-ui-fix.package` file. \
"**Export load-order**" will write the current patchset load-order to the "Import/Export" text-box. \
"**Import load-order**" will read and use a patchset load-order from the "Import/Export" text-box. \
"**Check for updates**" will check if there are any updates available for the Tiny UI Fix. \
"**Cancel**" will cancel any changes that have been made, and will cause the script to exit.

---

The script uses a library with an s3pi-compatible interface for manipulating Sims 3 package files. \
If the script cannot find such a library on your device, it will offer to download Peter Jones's [s3pi library](https://s3pi.sourceforge.net/).
On Windows, if you have S3PE installed its copy of s3pi will be used.

## Compatibility

Tiny UI Fix has been developed for and tested with version 1.67 of The Sims 3, but it should be compatible with version 1.69, and version 1.70.

Thanks to the dynamic nature with which this mod is generated, it should be compatible with the vast majority of mods, including core mods, such as the NRaas Industries suite of mods.
However, mods which perform hard-coded adjustments to UI coordinates or dimensions via C# DLLs will require a patch for full compatibility, otherwise some elements of the game's UI may be incorrectly positioned or sized. \
Such a patch is included with the Tiny UI Fix for the NRaas Industries suite of mods.

If you are a mod author and you would like to make your mod compatible with the Tiny UI Fix's UI scaling, A—thank you :), B—please see the [For mod authors section of this document](#for-mod-authors).

## Known issues

- Some icons and graphics are visually stretched in one dimension.
- Some icons disappear when they are selected.
- Scrollbars that would usually scroll smoothly when the arrows are clicked do not scroll smoothly.
- The options menu is @#$%&!ed.
- If Windows' "Controlled folder access" setting is enabled, and the Tiny UI Fix script is used to temporarily allow PowerShell to access controlled folders: if multiple instances of the script are run at around the same time, the script that allowed PowerShell to access controlled folders may disallow PowerShell from accessing controlled folders before the other instances of the script have finished writing, which could cause their writing to fail.

## How it works

The UI of the Sims 3 is composed of four distinct layers/components: XML layout files which specify the structure and content of the UI; CSS-based style files which specify the sizing, space, and style of text; .NET assemblies (C# DLLs) which can manipulate the UI controls/windows specified by the XML layout files; the game's C++ engine which actually draws the UI and handles interaction. \
When modding The Sims 3, we can toy about with the first three of those.

Thus, scaling the UI requires the following:
1. Scaling the font-sizes and line-spacing in the CSS-based style files. This is easy.
2. Scaling any pixel-based coordinates and dimensions in the XML layout files. This is also easy, but somewhat less so than the previous step.
3. In an ideal world, this list would stop here.
4. Remember how step two mentioned pixel-based coordinates and dimensions? Much of the UI code in the game's .NET assemblies manipulate those values using hard-coded, absolute, non-proportional values, so if the layouts are scaled those hard-coded values also have to be scaled. \
This is achieved by manually identifying the hard-coded values in any offending .NET assemblies, and writing automated patches that rewrite the code to scale the hard-coded values by the UI-scale multiplier. \
At-least 450 methods were manually inspected for the game's built-in assemblies, with \~343 of them requiring patches. \
Jb Evain et al.'s [Mono.Cecil library](https://github.com/jbevain/cecil) was used to implement this manipulation of the .NET assemblies.
5. In a less cruel world, this list would stop here.
6. Despite all this, it turns out that game's C++ code (remember it?) for drawing scrollbars and sliders doesn't respect the scale specified for them in the XML layout files, and so they always draw at the original UI-scale—this is perhaps stomachable for scrollbars, but sliders are still literally unusable because of how small they are at high-DPI resolutions. \
To remedy this how-de-do, the Tiny UI Fix reimplements the slider and scrollbar controls from scratch (ask how fun that was), and hooks the game's function for retrieving window-instances from a window-handle to draw the scaled mimic controls over the actual controls (and it attempts to this do this until the mimicry actually succeeds, or else the mimic controls don't appear and the actual controls break (ask how fun _that_ was to debug)). (They actually get drawn far-far to the left of the actual control, which itself gets moved far-far to the right until it's off-screen). \
And then, to make sure that everything works as it's supposed to, events for the mimic controls are forwarded to the original controls (naturally, events for event registration and deregistration were implemented and patched in).
7. You know the drill. This list should have stopped long ago.
8. A number of the game's scrollbar and slider controls use a win-proc (window-procedure) to control their layout, specifically the `SimpleLayout` win-proc which allows a control to be anchored to its parent in regards to a combination of directions. \
There is no way to inspect if a control uses such a win-proc from within the confines of the game's .NET runtime (at-least, I couldn't find a way), and the usual coordinates for such controls are then wrong—so the XML layout (remember those?) scaler was rejigged to keep track of the control-IDs for scrollbars and sliders (and of their ancestors) which use layout-affecting win-procs. Those control-IDs are then arranged into a tree that the Tiny UI Fix can query at runtime to check if a scaled mimic control should be drawn with an anchor or not.
9. This list ends here.
10. actually no—make it easy to patch arbitrary combinations of mods kthxbye.

## For mod authors

### Making your mod compatible with Tiny UI Fix

If your mod relies on hard-coded adjustments being made to the coordinates or dimensions of a UI control via a C# DLL those adjustments will be incorrect when the UI is scaled. \
The Tiny UI Fix has been designed to make it easy for other mods to integrate with the Tiny UI Fix's UI scaling, so no changes are needed to your mod's build process, nor is an assembly reference required, nor does the load-order of the mods matter.

To integrate with the UI scaling added by the Tiny UI Fix: define a class named `TinyUIFixForTS3Integration` in a namespace of your mod, and then in that class define a static member named `getUIScale`, the type of the `getUIScale` member should be a delegate-type that takes no parameters and returns a float, make the default value for the `getUIScale` member a delegate that returns `1.0f` (that way, if the Tiny UI Fix isn't present, your UI scale will be usual scale of 1x).

To illustrate, your code should look something like:

```csharp
namespace YourCoolMod
{
	public static class TinyUIFixForTS3Integration
	{
		public delegate float FloatGetter ();

		public static FloatGetter getUIScale = () => 1f;
	}
}
```

which you would then use like so:

```csharp
namespace YourCoolMod
{
	public class YourEventHandler
	{
		public void OnChangeOfAreaOfControl (WindowBase sender, UIAreaChangeEventArgs eventArgs)
		{
			sender.Position += 50f * TinyUIFixForTS3Integration.getUIScale();
		}
	}
}
```

And that's it!

---

Some technical notes: \
The Tiny UI Fix offers the following guarantees:
- The delegates that it sets for the `getUIScale` field will always be non-null, and the value that those delegates return will always satisfy the following condition: `uiScale > 0f && uiScale < float.PositiveInfinity`, that is, the UI-scale will always be a positive number. You don't have to worry about dividing-by-zero or infinity values or NaN values or anything like that.
- If a .NET module defines multiple `TinyUIFixForTS3Integration` types, then the order in which they are integrated in is the order in which they are sorted in ascending order by `StringComparer.Ordinal.Compare(a.FullName, b.FullName)`.
- The order in which .NET modules and .NET assemblies are integrated in is undefined.

## Building/Development

The Tiny UI Fix consists of a mixture of PowerShell, C#, and a few XML resources, and they're expected to be arranged in a specific manner; this necessitates a build step. \
Git submodules are used for dependency management, so ensure that they're cloned in your local repository.

There are multiple build scripts which can be found in the `Building` directory. \
All the build scripts require PowerShell 5.1, but PowerShell 7.0-or-later are preferred as they can use `ForEach-Object -Parallel` for faster builds. \
The `dotnet` CLI tool is used for building the C# code. The latest .NET version that's targeted is v4.7.1 of the .NET Framework, so any even-vaguely up-to-date version of the .NET SDK will do.

Some of the build scripts require that a path to a directory containing the Sims 3's assemblies is supplied via the `AssemblyPaths` parameter, if the parameter isn't supplied it defaults to including `../../../Assemblies/1.67`. \
If you haven't already extracted the Sims 3's assemblies from the game files, see the ["Getting Started" section of this wiki article](https://modthesims.info/wiki.php?title=Tutorial:Sims_3_Pure_Scripting_Modding#Getting_Started).

The C# component of this mod expects that the Sims 3 assemblies used for the building of the mod have been modified to have all definitions been made public—a tool is included in this repository to do that, which can be invoked like so: `Get-ChildItem -LiteralPath ../../../Assemblies/1.67 | Tools/Invoke-OpenSesame.ps1.`

`Building/Build-All.ps1` builds everything needed for the mod.

`Building/Package-TinyUIFixForTS3Patcher.ps1` builds everything needed for the mod, and then arranges it all into a directory in a ready-to-execute fashion. \
It has a few options to skip various builds to keep the development loop quick.
Additionally, it has a `MakeDevelopmentCopy` switch which will create a copy of the packaged mod to the `Build/Package/Development` directory: this is because a PowerShell process locks a DLL file when it is added as a type, so using the `Development` folder for development allows for the actual release/debug packages to have their DLL files freely replaced.

For the most part, the development loop is as so:
```powershell
./Building/Package-TinyUIFixForTS3Patcher.ps1 -MakeDevelopmentCopy -SkipBuildOfPatcher
./Build/Package/Development/TinyUIFixForTS3/Use-TinyUIFixForTS3.ps1 -GenerateUncompressedPackage
```

Lastly, there is the `Building/Package-SingleFileDistributables.ps1` script which will package the files collated by `Package-TinyUIFixForTS3Patcher.ps1` into multiple single-file distributables: a Batch file for Windows; a Shell script for macOS; a zip-archive for any platform.

## Licensing

Tiny UI Fix for The Sims 3, and its accompanying documentation, is distributed under the [Boost Software License, Version 1.0](https://www.boost.org/LICENSE_1_0.txt).

## Acknowledgements

Jb Evain and all contributors for the [Mono.Cecil library](https://github.com/jbevain/cecil), which is used for .NET assembly manipulation. \
Peter Jones, Inge Jones, and all contributors for the [s3pi library](https://s3pi.sourceforge.net/), which is used as the default choice for Sims 3 package manipulation.

