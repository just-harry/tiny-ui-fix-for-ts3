
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
$TinyUIFixPath = $Data.TinyUIFixPatcherPath
$TinyUIFixBuildSuffix = "$Configuration/$TargetFramework"
$TinyUIFixPatcherAssemblyPrefix = $Data.TinyUIFixPatcherAssemblyPrefix

$Platforms = @('x64', 'x86', 'arm', 'arm64', 'anycpu')

New-Item -ItemType Directory -Force -Path $BuildPath > $Null

ForEach-InParallel $Platforms `
{
	if (-not $IsSerial)
	{
		$BuildPath = $Using:BuildPath
		$Configuration = $Using:Configuration
		$TargetFramework = $Using:TargetFramework
		$TinyUIFixBuildSuffix = $Using:TinyUIFixBuildSuffix
		$TinyUIFixPatcherAssemblyPrefix = $Using:TinyUIFixPatcherAssemblyPrefix
		$TinyUIFixPath = $Using:TinyUIFixPath
	}

	$Platform = $_

	dotnet `
		build `
		"-c=$Configuration" `
		"-p:TargetFramework=$TargetFramework" `
		"-p:platform=$Platform" `
		"-p:$(if ($PSNativeCommandArgumentPassing -eq 'Legacy') {'\'})`"AssemblyPath=$BuildPath$(if ($PSNativeCommandArgumentPassing -eq 'Legacy') {'\'})`"" `
		$TinyUIFixPath `
	| Write-Host

	if ($LASTEXITCODE -ne 0)
	{
		exit $LASTEXITCODE
	}

	Get-ChildItem -Recurse -LiteralPath (Join-Path $TinyUIFixPath "bin/$(if ($Platform -ne 'anycpu') {"$Platform/"})$TinyUIFixBuildSuffix") | % `
	{
		if ($_.Name.StartsWith($TinyUIFixPatcherAssemblyPrefix))
		{
			Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $BuildPath "$($_.BaseName).$Platform$($_.Extension)")
		}
	}
}


