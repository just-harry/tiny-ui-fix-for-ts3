
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
$TinyUIFixPath = Join-Path $PSScriptRoot TinyUIFixForTS3
$ToolsPath = Join-Path $PSScriptRoot Tools

[PSCustomObject] @{
	Root = $PSScriptRoot
	LicencesPath = Join-Path $PSScriptRoot Licences
	BuildRoot = $BuildRoot
	BuildBinPath = Join-Path $BuildRoot Bin
	BuildDataPath = Join-Path $BuildRoot Data
	PackageRoot = Join-Path $BuildRoot Package
	PackageSuffix = 'TinyUIFixForTS3'
	CecilPath = Join-Path $DependenciesPath Cecil
	SEEPSSEFEUPath = Join-Path $DependenciesPath seepssefeu
	TinyUIFixPath = $TinyUIFixPath
	TinyUIFixPatcherPath = Join-Path $TinyUIFixPath Patcher
	TinyUIFixPatcherAssemblyPrefix = 'TinyUIFixForTS3Patcher'
	TinyUIFixPatchPath = Join-Path $TinyUIFixPath Patch
	TinyUIFixPatchAssemblyPrefix = 'TinyUIFixForTS3'
	TinyUIFixPatchsetsPath = Join-Path $TinyUIFixPath Patchsets
	TinyUIFixCoreBridgePath = Join-Path $TinyUIFixPath CoreBridge
	TinyUIFixCoreBridgeAssemblyPrefix = 'TinyUIFixForTS3CoreBridge'
	OpenSesamePath = Join-Path $ToolsPath OpenSesame
}

