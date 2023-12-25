
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

$Data = & (Join-Path $PSScriptRoot ../Data.ps1)

$TargetFramework = 'net40'

$BuildPath = $Data.BuildBinPath
$CecilPath = $Data.CecilPath
$CecilBuildPath = Join-Path $CecilPath "bin/$Configuration/$TargetFramework"
$CecilRocksPath = Join-Path $Data.CecilPath rocks
$CecilRocksBuildPath = Join-Path $CecilRocksPath "bin/$Configuration/$TargetFramework"

dotnet `
	build `
	"-c=$Configuration" `
	"-p:TargetFramework=$TargetFramework" `
	$CecilPath `
| Write-Host

if ($LASTEXITCODE -ne 0)
{
	exit $LASTEXITCODE
}

New-Item -ItemType Directory -Force -Path $BuildPath > $Null

Copy-Item -Recurse -Force -Path (Join-Path $CecilBuildPath *) -Destination $BuildPath
Copy-Item -Recurse -Force -Path (Join-Path $CecilRocksBuildPath *) -Destination $BuildPath

