
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

[CmdletBinding()]
Param ()

$DependenciesPath = Join-Path $PSScriptRoot Dependencies
$BuildRoot = Join-Path $PSScriptRoot Build

[PSCustomObject] @{
	LicencesPath = Join-Path $PSScriptRoot Licences
	BuildRoot = $BuildRoot
	BuildBinPath = Join-Path $BuildRoot Bin
	CecilPath = Join-Path $DependenciesPath Cecil
}

