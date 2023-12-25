
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
			$AssemblyPaths,

	[Parameter()]
		[ValidateNotNull()]
			$Configuration = 'Release'
)

. (Join-Path $PSScriptRoot ../Common.ps1)
$Data = & (Join-Path $PSScriptRoot ../Data.ps1)

$TargetFramework = 'net471'


$BuildPath = $Data.BuildBinPath
$OpenSesamePath = $Data.OpenSesamePath
$OpenSesameBuildPath = Join-Path $OpenSesamePath "bin/$Configuration/$TargetFramework"

if (-not (Test-Path -LiteralPath (Join-Path $BuildPath Mono.Cecil.dll)))
{
	& (Join-Path $PSScriptRoot Building/Build-Cecil.ps1) -AssemblyPaths $AssemblyPaths -Configuration $Configuration
}

dotnet `
	build `
	"-c=$Configuration" `
	"-p:TargetFramework=$TargetFramework" `
	"-p:$(if ($PSNativeCommandArgumentPassing -eq 'Legacy') {'\'})`"AssemblyPath=$BuildPath$(if ($PSNativeCommandArgumentPassing -eq 'Legacy') {'\'})`"" `
	$OpenSesamePath `
| Write-Host

if ($LASTEXITCODE -ne 0)
{
	exit $LASTEXITCODE
}

New-Item -ItemType Directory -Force -Path $BuildPath > $Null

Copy-Item -Recurse -Force -Path (Join-Path $OpenSesameBuildPath *) -Destination $BuildPath

