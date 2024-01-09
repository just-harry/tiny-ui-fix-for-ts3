
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
			$Configuration = 'Release'
)

$Data = & (Join-Path $PSScriptRoot ../Data.ps1)

. (Join-Path $Data.SEEPSSEFEUPath seepssefeu.ps1)

# v7.2.9 is the last version of v7.2 of PowerShell that just works™ on High Sierra (macOS 10.13).
$MacOSX86PowerShellSource = @{
	Length = 66352798
	SHA256Hash = '4b6ca38156561d028ad346ad7539592c04ea2c09bfdf6da59b3a72a1dd39d2ee'
	URL = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.9/powershell-7.2.9-osx-x64.tar.gz'
	BackupURL = 'https://web.archive.org/web/20231224022647if_/https://objects.githubusercontent.com/github-production-release-asset-2e65be/49609581/849751a5-b919-40fc-96af-e83a6af58c64?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20231224%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231224T022646Z&X-Amz-Expires=300&X-Amz-Signature=f146914758e77a90c306a7abcdaf0a5e5e5a6ec5b9d7bf926ae097133b2e2bfa&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=49609581&response-content-disposition=attachment%3B%20filename%3Dpowershell-7.2.9-osx-x64.tar.gz&response-content-type=application%2Foctet-stream'
}
$MacOSARMPowerShellSource = @{
	Length = 62638308
	SHA256Hash = 'd34572d97ef4002b361fdedac51a9bca39b4b2d1e526e7355de062063ae9f8bf'
	URL = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.9/powershell-7.2.9-osx-arm64.tar.gz'
	BackupURL = 'https://web.archive.org/web/20231224022847if_/https://objects.githubusercontent.com/github-production-release-asset-2e65be/49609581/9c2bf5fd-adab-4dce-b2ad-3bda40780bcb?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20231224%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231224T022847Z&X-Amz-Expires=300&X-Amz-Signature=5533d582dd573c555c0f48100c66b2d09ab12ee8eb737e5940612d89a73b8711&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=49609581&response-content-disposition=attachment%3B%20filename%3Dpowershell-7.2.9-osx-arm64.tar.gz&response-content-type=application%2Foctet-stream'
}

$PackageRoot = $Data.PackageRoot
$PackageSuffix = $Data.PackageSuffix
$PackagePath = Join-Path $PackageRoot $Configuration
$TinyUIFixForTS3Path = Join-Path $PackagePath $PackageSuffix

$UTF8 = [Text.UTF8Encoding]::new($False, $False)

$Get = {Param ($Path) Get-Item -LiteralPath (Join-Path $TinyUIFixForTS3Path $Path) -ErrorAction Stop}

$Files = @(
	@{File = & $Get Licences/Mono.Cecil.txt; Encoding = $UTF8; Destination = 'Licences/Mono.Cecil.txt'}
	@{File = & $Get Use-TinyUIFixForTS3.ps1; Encoding = $UTF8; Destination = 'Use-TinyUIFixForTS3.ps1'}
	@{File = & $Get Patchsets/Nucleus.ps1; Encoding = $UTF8; Destination = 'Patchsets/Nucleus.ps1'}
	@{File = & $Get Patchsets/VanillaCoreCompatibilityPatch.ps1; Encoding = $UTF8; Destination = 'Patchsets/VanillaCoreCompatibilityPatch.ps1'}
	@{File = & $Get Patchsets/CompatibilityPatchesForNRaasMods.ps1; Encoding = $UTF8; Destination = 'Patchsets/CompatibilityPatchesForNRaasMods.ps1'}
	@{File = & $Get Patchsets/CompatibilityPatchForSmoothPatch.ps1; Encoding = $UTF8; Destination = 'Patchsets/CompatibilityPatchForSmoothPatch.ps1'}
	@{File = & $Get Data/ConfiguratorIndexPage.ps1; Encoding = $UTF8; Destination = 'Data/ConfiguratorIndexPage.ps1'}
	@{File = & $Get Data/Unblock-PowerShellForControlledFolderAccess.ps1; Encoding = $UTF8; Destination = 'Data/Unblock-PowerShellForControlledFolderAccess.ps1'}
	@{File = & $Get Data/TinyUIFixForTS3.xml; Encoding = $UTF8; Destination = 'Data/TinyUIFixForTS3.xml'}
	@{File = & $Get Data/ScaledHorizontalScrollbarMimic.xml; Encoding = $UTF8; Destination = 'Data/ScaledHorizontalScrollbarMimic.xml'}
	@{File = & $Get Data/ScaledHorizontalSliderMimic.xml; Encoding = $UTF8; Destination = 'Data/ScaledHorizontalSliderMimic.xml'}
	@{File = & $Get Data/ScaledVerticalScrollbarMimic.xml; Encoding = $UTF8; Destination = 'Data/ScaledVerticalScrollbarMimic.xml'}
	@{File = & $Get Data/ScaledVerticalSliderMimic.xml; Encoding = $UTF8; Destination = 'Data/ScaledVerticalSliderMimic.xml'}
	@{File = & $Get Binaries/Mono.Cecil.dll; Destination = 'Binaries/Mono.Cecil.dll'}
	@{File = & $Get Binaries/Mono.Cecil.pdb; Destination = 'Binaries/Mono.Cecil.pdb'}
	@{File = & $Get Binaries/Mono.Cecil.Rocks.dll; Destination = 'Binaries/Mono.Cecil.Rocks.dll'}
	@{File = & $Get Binaries/Mono.Cecil.Rocks.pdb; Destination = 'Binaries/Mono.Cecil.Rocks.pdb'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.anycpu.dll; Destination = 'Binaries/TinyUIFixForTS3Patcher.anycpu.dll'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.anycpu.pdb; Destination = 'Binaries/TinyUIFixForTS3Patcher.anycpu.pdb'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.arm.dll; Destination = 'Binaries/TinyUIFixForTS3Patcher.arm.dll'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.arm.pdb; Destination = 'Binaries/TinyUIFixForTS3Patcher.arm.pdb'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.arm64.dll; Destination = 'Binaries/TinyUIFixForTS3Patcher.arm64.dll'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.arm64.pdb; Destination = 'Binaries/TinyUIFixForTS3Patcher.arm64.pdb'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.x64.dll; Destination = 'Binaries/TinyUIFixForTS3Patcher.x64.dll'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.x64.pdb; Destination = 'Binaries/TinyUIFixForTS3Patcher.x64.pdb'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.x86.dll; Destination = 'Binaries/TinyUIFixForTS3Patcher.x86.dll'}
	@{File = & $Get Binaries/TinyUIFixForTS3Patcher.x86.pdb; Destination = 'Binaries/TinyUIFixForTS3Patcher.x86.pdb'}
	@{File = & $Get Data/TinyUIFixForTS3.dll; Destination = 'Data/TinyUIFixForTS3.dll'}
	@{File = & $Get Data/TinyUIFixForTS3.pdb; Destination = 'Data/TinyUIFixForTS3.pdb'}
	@{File = & $Get Data/TinyUIFixForTS3CoreBridge.dll; Destination = 'Data/TinyUIFixForTS3CoreBridge.dll'}
	@{File = & $Get Data/TinyUIFixForTS3CoreBridge.pdb; Destination = 'Data/TinyUIFixForTS3CoreBridge.pdb'}
)

$Scripts = New-SEEPSSEFEU `
	-Files $Files `
	-DestinationBase tiny-ui-fix-for-ts3 `
	-ScriptToRun Use-TinyUIFixForTS3.ps1 `
	-TerminalWindowTitle 'Tiny UI Fix for The Sims 3' `
	-MakeZipInWindowsExplorerFriendlyVersion `
	-PowerShellTarballSourceForX86 $MacOSX86PowerShellSource `
	-PowerShellTarballSourceForARM $MacOSARMPowerShellSource

$WindowsPath = Join-Path $PackagePath tiny-ui-fix-for-ts3.bat
$WindowsZipPath = "$WindowsPath.zip"
$MacOSPath = Join-Path $PackagePath tiny-ui-fix-for-ts3.command
$MacOSZipPath = "$MacOSPath.zip"

[IO.File]::WriteAllText($WindowsPath, $Scripts.Windows.ToString(), $UTF8)
[IO.File]::WriteAllText($MacOSPath, $Scripts.MacOS.ToString(), $UTF8)

Compress-Archive -Force -CompressionLevel Optimal -LiteralPath $MacOSPath -DestinationPath $MacOSZipPath


$ZipScratchPath = Join-Path $PackagePath ZipScratch
$ZipArchivePath = Join-Path $PackagePath tiny-ui-fix-for-ts3.zip

Remove-Item -Recurse -Force -LiteralPath $ZipScratchPath -ErrorAction Ignore
New-Item -ItemType Directory -Force -Path $ZipScratchPath > $Null

$WindowsZipBatPath = Join-Path $ZipScratchPath tiny-ui-fix-for-ts3.bat

[IO.File]::WriteAllText($WindowsZipBatPath, $Scripts.WindowsZipInWindowsExplorerFriendly.ToString(), $UTF8)
Compress-Archive -Force -CompressionLevel Optimal -LiteralPath $WindowsZipBatPath -DestinationPath $WindowsZipPath
Remove-Item -Force -LiteralPath $WindowsZipBatPath -ErrorAction Ignore

foreach ($File in $Files)
{
	$DestinationPath = Join-Path $ZipScratchPath $File.Destination

	New-Item -ItemType Directory -Force -Path (Split-Path $DestinationPath) > $Null
	Copy-Item -LiteralPath $File.File.FullName -Destination $DestinationPath -Force
}

Compress-Archive -Force -CompressionLevel Optimal -LiteralPath (Get-ChildItem -LiteralPath $ZipScratchPath).FullName -DestinationPath $ZipArchivePath
Remove-Item -Recurse -Force -LiteralPath $ZipScratchPath -ErrorAction Ignore


<# This is so ridiculously stupid. Why not just expose the "version made by" field? It's but a harmless ushort.  #>
class BadZipArchiveAPIWorkaroundStream : IO.Stream
{
	[IO.Stream] $BaseStream
	[Int64] $PositionOfLastSignature
	[Collections.Generic.HashSet[Int64]] $SignaturesEncountered

	BadZipArchiveAPIWorkaroundStream ([IO.Stream] $BaseStream)
	{
		$This.BaseStream = $BaseStream
		$This.PositionOfLastSignature = [Int64]::MinValue
		$This.SignaturesEncountered = [Collections.Generic.HashSet[Int64]]::new(1)
	}

	[Void] Write ([Byte[]] $Buffer, [Int32] $Offset, [Int32] $Count)
	{
		if (
			     $Count -eq 4 `
			-and $Buffer[0] -eq 0x50 `
			-and $Buffer[1] -eq 0x4B `
			-and $Buffer[2] -eq 0x01 `
			-and $Buffer[3] -eq 0x02
		)
		{
			$This.PositionOfLastSignature = $This.BaseStream.Position
			$This.SignaturesEncountered.Add($This.PositionOfLastSignature)
		}
		elseif ($This.BaseStream.Position -eq $This.PositionOfLastSignature + 5)
		{
			$Buffer[0] = 3
		}

		$This.BaseStream.Write($Buffer, $Offset, $Count)
	}

	[Int32] WriteByte ([Byte] $Value)
	{
		if ($This.BaseStream.Position -eq $This.PositionOfLastSignature + 5)
		{
			$Value = 3
		}

		return $This.BaseStream.WriteByte($Value)
	}

	[Int32] Read ([Byte[]] $Buffer, [Int32] $Offset, [Int32] $Count) {return $This.BaseStream.Read($Buffer, $Offset, $Count)}
	[Int32] ReadByte () {return $This.BaseStream.ReadByte()}
	[Bool] get_CanRead () {return $This.BaseStream.CanRead}
	[Bool] get_CanSeek () {return $This.BaseStream.CanSeek}
	[Bool] get_CanWrite () {return $This.BaseStream.CanWrite}
	[Void] Flush () {$This.BaseStream.Flush()}
	[Int64] get_Length () {return $This.BaseStream.Length}
	[Int64] get_Position () {return $This.BaseStream.Position}
	[Void] set_Position ([Int64] $Position) {$This.BaseStream.Position = $Position}
	[Void] SetLength ([Int64] $Length) {$This.BaseStream.SetLength($Length)}
	[Int64] Seek ([Int64] $Offset, [IO.SeekOrigin] $Origin) {return $This.BaseStream.Seek($Offset, $Origin)}
	[Void] Dispose ([Bool] $Disposing) {$This.BaseStream.Dispose()}
}


if ($Null -eq ([Management.Automation.PSTypeName] 'System.IO.Compression.ZipFile').Type)
{
	Add-Type -Assembly 'System.IO.Compression.FileSystem'
}


$MacOSZipArchive = $Null
$WorkaroundStream = $Null
$EntryCount = 0

try
{
	$WorkaroundStream = [BadZipArchiveAPIWorkaroundStream]::new(
		[IO.FileStream]::new($MacOSZipPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read -bor [IO.FileShare]::Delete)
	)
	$MacOSZipArchive = [IO.Compression.ZipArchive]::new($WorkaroundStream, [IO.Compression.ZipArchiveMode]::Update)
	$EntryCount = $MacOSZipArchive.Entries.Count

	foreach ($Entry in $MacOSZipArchive.Entries)
	{
		$Attributes = $Entry.ExternalAttributes             # rwxrwxr-x                   # mystery bit. (Safari will strip the file-permissions if it isn't set).
		$Attributes = $Attributes -bor (([Convert]::ToInt32('111111101', 2) -shl 16) -bor (1 -shl 31))
		$Entry.ExternalAttributes = $Attributes
	}
}
finally
{
	if ($Null -ne $MacOSZipArchive)
	{
		$MacOSZipArchive.Dispose()

		if ($WorkaroundStream.SignaturesEncountered.Count -ne $EntryCount)
		{
			Write-Error -ErrorAction Continue "`"$MacOSZipPath`" might be corrupt, as it has $EntryCount entr$(if ($EntryCount -eq 1) {'y'} else {'ies'}), but $($WorkaroundStream.SignaturesEncountered.Count) signature$(if ($WorkaroundStream.SignaturesEncountered.Count -ne 1) {'s were'} else {' was'}) encountered."
		}
	}
}


[PSCustomObject] @{
	Windows = Get-Item -LiteralPath $WindowsPath
	WindowsZip = Get-Item -LiteralPath $WindowsZipPath
	MacOS = Get-Item -LiteralPath $MacOSPath
	MacOSZip = Get-Item -LiteralPath $MacOSZipPath
	ZipArchive = Get-Item -LiteralPath $ZipArchivePath
}

