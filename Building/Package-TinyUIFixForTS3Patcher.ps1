
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

[CmdletBinding()]
Param
(
	[Parameter()]
		[ValidateNotNull()]
			$Configuration = 'Release',

	[Parameter()]
			[Switch] $SkipBuild,

	[Parameter()]
			[Switch] $SkipBuildOfPatch,

	[Parameter()]
			[Switch] $SkipBuildOfCoreBridge,

	[Parameter()]
			[Switch] $SkipBuildOfPatcher,

	[Parameter()]
			[Switch] $MakeDevelopmentCopy
)

$Data = & (Join-Path $PSScriptRoot ../Data.ps1)

if (-not $SkipBuild)
{
	& (Join-Path $PSScriptRoot Build-All.ps1) -Configuration $Configuration -SkipBuildOfPatch:$SkipBuildOfPatch -SkipBuildOfCoreBridge:$SkipBuildOfCoreBridge -SkipBuildOfPatcher:$SkipBuildOfPatcher
}

Add-Type -AssemblyName Microsoft.VisualBasic

$LicencesPath = $Data.LicencesPath
$BuildBinPath = $Data.BuildBinPath
$BuildDataPath = $Data.BuildDataPath
$PackagePath = $Data.PackageRoot
$PackageSuffix = $Data.PackageSuffix
$TinyUIFixPath = $Data.TinyUIFixPatcherPath
$TinyUIFixPatchPath = $Data.TinyUIFixPatchPath
$TinyUIFixPatchsetsPath = $Data.TinyUIFixPatchsetsPath
$TinyUIFixForTS3Path = Join-Path $PackagePath "$Configuration/$PackageSuffix"
$TinyUIFixForTS3LicencesPath = Join-Path $TinyUIFixForTS3Path Licences
$TinyUIFixForTS3BinariesPath = Join-Path $TinyUIFixForTS3Path Binaries
$TinyUIFixForTS3DBPFPath = Join-Path $TinyUIFixForTS3BinariesPath DBPF
$TinyUIFixForTS3DataPath = Join-Path $TinyUIFixForTS3Path Data
$TinyUIFixForTS3PatchsetsPath = Join-Path $TinyUIFixForTS3Path Patchsets

Remove-Item -Recurse -Force $TinyUIFixForTS3Path -ErrorAction Ignore

New-Item -ItemType Directory -Force -Path $TinyUIFixForTS3LicencesPath > $Null
New-Item -ItemType Directory -Force -Path $TinyUIFixForTS3BinariesPath > $Null
New-Item -ItemType Directory -Force -Path $TinyUIFixForTS3DBPFPath > $Null
New-Item -ItemType Directory -Force -Path $TinyUIFixForTS3DataPath > $Null
New-Item -ItemType Directory -Force -Path $TinyUIFixForTS3PatchsetsPath > $Null

try {[Microsoft.VisualBasic.FileIO.FileSystem]::CopyDirectory($LicencesPath, $TinyUIFixForTS3LicencesPath, $True)}
catch {}
Get-ChildItem -LiteralPath $BuildBinPath | % {[IO.File]::Copy($_.FullName, (Join-Path $TinyUIFixForTS3BinariesPath $_.Name), $True)}
Get-ChildItem -LiteralPath $BuildDataPath | % {[IO.File]::Copy($_.FullName, (Join-Path $TinyUIFixForTS3DataPath $_.Name), $True)}
Copy-Item -LiteralPath (Join-Path $TinyUIFixPatchPath TinyUIFixForTS3.xml) -Force -Destination $TinyUIFixForTS3DataPath
Copy-Item -LiteralPath (Join-Path $TinyUIFixPath Use-TinyUIFixForTS3.ps1) -Force -Destination $TinyUIFixForTS3Path
Copy-Item -LiteralPath (Join-Path $TinyUIFixPath ConfiguratorIndexPage.ps1) -Force -Destination $TinyUIFixForTS3DataPath
Copy-Item -LiteralPath (Join-Path $TinyUIFixPath Unblock-PowerShellForControlledFolderAccess.ps1) -Force -Destination $TinyUIFixForTS3DataPath
Copy-Item -LiteralPath (Join-Path $TinyUIFixPatchPath ScaledVerticalScrollbarMimic.xml) -Force -Destination $TinyUIFixForTS3DataPath
Copy-Item -LiteralPath (Join-Path $TinyUIFixPatchPath ScaledHorizontalScrollbarMimic.xml) -Force -Destination $TinyUIFixForTS3DataPath
Copy-Item -LiteralPath (Join-Path $TinyUIFixPatchPath ScaledVerticalSliderMimic.xml) -Force -Destination $TinyUIFixForTS3DataPath
Copy-Item -LiteralPath (Join-Path $TinyUIFixPatchPath ScaledHorizontalSliderMimic.xml) -Force -Destination $TinyUIFixForTS3DataPath
try {[Microsoft.VisualBasic.FileIO.FileSystem]::CopyDirectory($TinyUIFixPatchsetsPath, $TinyUIFixForTS3PatchsetsPath, $True)}
catch {}

if ($MakeDevelopmentCopy)
{
	$DevelopmentCopyRoot = Join-Path $PackagePath Development
	$DevelopmentCopyPath = Join-Path $DevelopmentCopyRoot $PackageSuffix

	Remove-Item -Recurse -Force $DevelopmentCopyPath -ErrorAction Ignore

	try {[Microsoft.VisualBasic.FileIO.FileSystem]::CopyDirectory($TinyUIFixForTS3Path, $DevelopmentCopyPath, $True)}
	catch {}
}

