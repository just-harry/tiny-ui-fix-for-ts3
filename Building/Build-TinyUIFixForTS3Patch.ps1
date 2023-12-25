
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
			$Configuration = 'Release'
)

. (Join-Path $PSScriptRoot ../Common.ps1)
$Data = & (Join-Path $PSScriptRoot ../Data.ps1)

$TargetFramework = 'net20'

$BuildPath = $Data.BuildDataPath
$TinyUIFixPath = $Data.TinyUIFixPatchPath
$TinyUIFixBuildSuffix = "$Configuration/$TargetFramework"
$TinyUIFixPatchAssemblyPrefix = $Data.TinyUIFixPatchAssemblyPrefix

New-Item -ItemType Directory -Force -Path $BuildPath > $Null


dotnet `
	build `
	"-c=$Configuration" `
	"-p:TargetFramework=$TargetFramework" `
	"-p:$(if ($PSNativeCommandArgumentPassing -eq 'Legacy') {'\'})`"AssemblyPath=$BuildPath;$([String]::Join(';', $AssemblyPaths))$(if ($PSNativeCommandArgumentPassing -eq 'Legacy') {'\'})`"" `
	$TinyUIFixPath `
| Write-Host

if ($LASTEXITCODE -ne 0)
{
	exit $LASTEXITCODE
}

Get-ChildItem -Recurse -LiteralPath (Join-Path $TinyUIFixPath "bin/$TinyUIFixBuildSuffix") | % `
{
	if ($_.Name.StartsWith($TinyUIFixPatchAssemblyPrefix))
	{
		Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $BuildPath $_.Name)
	}
}

