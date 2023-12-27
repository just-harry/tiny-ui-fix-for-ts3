
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
		[AllowEmptyCollection()]
			$AssemblyPaths = @((Join-Path $PSScriptRoot '../../../Assemblies/1.67')),

	[Parameter()]
		[ValidateNotNull()]
			$Configuration = 'Release',

	[Parameter()]
			[Switch] $SkipBuildOfPatch,

	[Parameter()]
			[Switch] $SkipBuildOfCoreBridge,

	[Parameter()]
			[Switch] $SkipBuildOfPatcher
)

$ScriptRoot = $PSScriptRoot

. (Join-Path $PSScriptRoot ../Common.ps1)

$Arguments = @{AssemblyPaths = $AssemblyPaths; Configuration = $Configuration}

if (-not $SkipBuildOfCoreBridge)
{
	& (Join-Path $ScriptRoot Build-TinyUIFixForTS3CoreBridge.ps1) @Arguments
}

ForEach-InParallel $(
	if (-not $SkipBuildOfPatcher) {,@('Build-Cecil.ps1', 'Build-TinyUIFixForTS3Patcher.ps1')}
	if (-not $SkipBuildOfPatch) {,@('Build-TinyUIFixForTS3Patch.ps1')}
) `
{
	if (-not $IsSerial)
	{
		$Arguments = $Using:Arguments
		$ScriptRoot = $Using:ScriptRoot
	}

	foreach ($Script in $_)
	{
		& (Join-Path $ScriptRoot $Script) @Arguments
	}
}

