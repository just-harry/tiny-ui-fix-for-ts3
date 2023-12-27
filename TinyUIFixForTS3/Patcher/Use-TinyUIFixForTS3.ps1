
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

[CmdletBinding()]
Param (
	[Parameter()]
			[Switch] $NonInteractive,

	[Parameter()]
			$PatchsetConfiguration,

	[Parameter()]
			[String[]] $PatchsetLoadOrder,

	[Parameter()]
			[Switch] $GetAvailablePatchsets,

	[Parameter()]
			[Switch] $GetStatusOfPatchsets,

	[Parameter()]
			[Switch] $GetPatchsetRecommendations,

	[Parameter()]
			[Switch] $GetResolvedPackagePriorities,

	[Parameter()]
			[Switch] $SkipGenerationOfPackage,

	[Parameter()]
			[Switch] $GenerateUncompressedPackage,

	[Parameter()]
			[Switch] $ChangeResourceCFGToLoadTinyUIFixLast,

	[Parameter()]
			[Switch] $SkipConfigurator,

	[Parameter()]
			[UInt16] $ConfiguratorPort,

	[Parameter()]
			$InstallationPlatform,

	[Parameter()]
			$DBPFManipulationLibraryPath,

	[Parameter()]
			$OutputUnpackedAssemblyDirectoryPath = $Null,

	[Parameter()]
			[Switch] $DoNotAutomaticallyAddTypes
)


if ($Null -eq $PSVersionTable -or ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1) -or $PSVersionTable.PSVersion.Major -eq 6))
{
	Write-Error 'This script requires version 5.1 of PowerShell, or at-least version 7, or later, of PowerShell.'

	exit 2
}


if (
	    $Null -eq ([Management.Automation.PSTypeName] 'System.ValueTuple').Type `
	-or (-not [ValueTuple].IsSerializable -and $Null -eq ([Management.Automation.PSTypeName] 'Runtime.CompilerServices.RuntimeFeature').Type)
)
{
	Write-Error 'This script requires at-least version 4.7.1, or later, of .NET to be installed.'

	exit 3
}


if ($PSVersionTable.PSVersion.Major -le 5)
{
	$IsWindows = $True
}
elseif ($IsOSX)
{
	$IsMacOS = $True
}

$IsWindowsOrMacOS = $IsWindows -or $IsMacOS


class TinyUIFixPSForTS3Exception : Exception
{
	[PSCustomObject] $Data

	TinyUIFixPSForTS3Exception ([String] $Message, [PSCustomObject] $Data) : base($Message)
	{
		$This.Data = $Data
	}
}

class TinyUIFixPSForTS3ConfiguratorException : TinyUIFixPSForTS3Exception {TinyUIFixPSForTS3ConfiguratorException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}
class TinyUIFixPSForTS3UnableToUseConfiguratorPortException : TinyUIFixPSForTS3ConfiguratorException {TinyUIFixPSForTS3UnableToUseConfiguratorPortException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}

class TinyUIFixPSForTS3FailedToDownloadFileException : TinyUIFixPSForTS3Exception {TinyUIFixPSForTS3FailedToDownloadFileException ([String] $Message, [PSCustomObject] $Data) : base($Message, $Data) {}}


function Get-ExpectedSims3Paths
{
	if ($Script:IsWindows)
	{
		[TinyUIFixPSForTS3]::WriteLineQuickly('Trying to find file-paths for your installation of The Sims 3.')

		[TinyUIFixPSForTS3]::UseDisposable(
			{[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)},
			{
				Param ($Registry)

				[PSCustomObject] @{
					Sims3Path = $(if (($Key = $Registry.OpenSubKey('SOFTWARE\Sims\The Sims 3'))) {$Key.GetValue('Install Dir')})
					S3PEPath = $(if (($Key = $Registry.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\s3pe'))) {$Key.GetValue('InstallLocation')})
					Sims3UserDataPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) 'Electronic Arts/The Sims 3'
				}
			}
		)
	}
	elseif ($Script:IsMacOS)
	{
		[TinyUIFixPSForTS3]::WriteLineQuickly('Trying to find file-paths for your installation of The Sims 3.')

		$Sims3Path = @(
			(Join-Path $Global:HOME 'Applications/Sims3Launcher.app/Contents/Resources/The Sims 3.app'),
			(Join-Path $Global:HOME 'Applications/The Sims 3.app'),
			'/Applications/Sims3Launcher.app/Contents/Resources/The Sims 3.app',
			'/Applications/The Sims 3.app'
		).Where({Test-Path -LiteralPath $_}, 'First')[0]

		[PSCustomObject] @{
			Sims3Path = if ($Null -ne $Sims3Path) {$Sims3Path} else {'/Applications/The Sims 3.app'}
			Sims3UserDataPath = Join-Path $Global:HOME 'Documents/Electronic Arts/The Sims 3'
		}
	}
	else
	{
		[PSCustomObject] @{}
	}
}


function Test-RequiredDBPFManipulationTypesAreLoaded
{
	     $Null -ne ([Management.Automation.PSTypeName] 's3pi.Interfaces.TGIBlock').Type `
	-and $Null -ne ([Management.Automation.PSTypeName] 's3pi.Package.Package').Type `
	-and $Null -ne ([Management.Automation.PSTypeName] 's3pi.DefaultResource.DefaultResource').Type `
	-and $Null -ne ([Management.Automation.PSTypeName] 'ScriptResource.ScriptResource').Type `
	-and $Null -ne ([Management.Automation.PSTypeName] 's3pi.WrapperDealer.WrapperDealer').Type
}


function Find-DBPFManipulationAssemblies ($DBPFManipulationLibraryPath = $Script:DBPFManipulationLibraryPath)
{
	$BinariesPath = Join-Path $PSScriptRoot Binaries
	$DBPFPath = if ($Null -eq $DBPFManipulationLibraryPath) {Join-Path $BinariesPath DBPF} else {$DBPFManipulationLibraryPath}
	$IsDLL = {$_.Name -match '\.(?:Package|Interfaces|DefaultResource|ScriptResource|WrapperDealer)\.dll$'}

	$Found = Get-ChildItem -LiteralPath $DBPFPath -ErrorAction Ignore | ? $IsDLL

	if ($Found.Count -eq 0 -and $Null -ne $Script:ExpectedSims3Paths.S3PEPath)
	{
		$Found = Get-ChildItem -LiteralPath $Script:ExpectedSims3Paths.S3PEPath -ErrorAction Ignore | ? $IsDLL
	}

	$Found
}


function Add-TypesForTinyUIFixForTS3 ($DBPFManipulationLibraryPath)
{
	$BinariesPath = Join-Path $PSScriptRoot Binaries

	if ($Null -eq ([Management.Automation.PSTypeName] 'Mono.Cecil.AssemblyDefinition').Type)
	{
		Add-Type -LiteralPath (Join-Path $BinariesPath Mono.Cecil.dll)
	}

	if ($Null -eq ([Management.Automation.PSTypeName] 'Mono.Cecil.Rocks.MethodBodyRocks').Type)
	{
		Add-Type -LiteralPath (Join-Path $BinariesPath Mono.Cecil.Rocks.dll)
	}

	if ($Null -eq ([Management.Automation.PSTypeName] 'TinyUIFixForTS3Patcher.LayoutScaler').Type)
	{
		$ProcessArchitecture = [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

		if ($PSVersionTable.PSVersion.Major -le 5)
		{
			if ($Null -eq $ProcessArchitecture)
			{
				$Domain = [AppDomain]::CreateDomain('Workaround PSReadline''s outdated Runtime.InteropServices.RuntimeInformation')
				$MSCorLib = $Domain.Load('mscorlib')
				$ProcessArchitecture = $MSCorLib.GetType('System.Runtime.InteropServices.RuntimeInformation').GetProperty('ProcessArchitecture').GetValue($Null)
				[AppDomain]::Unload($Domain)
			}
		}

		$PlatformMap = @{
			[Runtime.InteropServices.Architecture]::X64 = 'x64'
			[Runtime.InteropServices.Architecture]::X86 = 'x86'
			[Runtime.InteropServices.Architecture]::Arm64 = 'arm64'
			[Runtime.InteropServices.Architecture]::Arm = 'arm'
		}

		$Platform = if ($PSVersionTable.PSVersion.Major -le 5)
		{
			$PlatformMap[$ProcessArchitecture]
		}
		else
		{
			if ($Null -ne $ProcessArchitecture) {$PlatformMap[$ProcessArchitecture]}
		}

		if ($Null -eq $Platform) {$Platform = 'anycpu'}

		Add-Type -LiteralPath (Join-Path $BinariesPath "TinyUIFixForTS3Patcher.$Platform.dll")
	}

	if (-not (Test-RequiredDBPFManipulationTypesAreLoaded))
	{
		Find-DBPFManipulationAssemblies $DBPFManipulationLibraryPath | % {Add-Type -LiteralPath $_.FullName}
	}
}


if (-not $DoNotAutomaticallyAddTypes)
{
	Add-TypesForTinyUIFixForTS3 $DBPFManipulationLibraryPath
}


$TinyUIFixPSForTS3ResourceKeys = @{
	UIDLL = $Null
	SimIFaceDLL = $Null
	Sims3GameplaySystemsDLL = $Null
	Sims3GameplayObjectsDLL = $Null
	Sims3StoreObjectsDLL = $Null
	StyleGuideLayout = $Null
	TinyUIFixForTS3DLL = $Null
	TinyUIFixForTS3CoreBridge = $Null
	TinyUIFixForTS3XML = $Null
	TinyUIFixForTS3ScaledVerticalScrollbarMimic = $Null
	TinyUIFixForTS3ScaledHorizontalScrollbarMimic = $Null
	TinyUIFixForTS3ScaledVerticalSliderMimic = $Null
	TinyUIFixForTS3ScaledHorizontalSliderMimic = $Null
}


class TinyUIFixForTS3Logger
{
	[Void] WriteWarning ([String] $Text)
	{
		Write-Warning $Text -WarningAction Continue
	}

	[Void] WriteError ([String] $Text)
	{
		Write-Error $Text -ErrorAction Continue
	}

	[Void] WriteInfo ([String] $Text)
	{
		if ($Script:NonInteractive)
		{
			Write-Host $Text
		}
		else
		{
			[Console]::WriteLine($Text)
		}
	}

	TinyUIFixForTS3Logger ()
	{}
}


class TinyUIFixPSForTS3
{
	static [Version] $Version = [Version]::new(1, 0, 4)

	static [String] $GeneratedPackageName = 'tiny-ui-fix.package'
	static [String] $ModsFolderName = 'TinyUIFix'
	static [String] $GeneratePackagePackedFileDirective = "$([TinyUIFixPSForTS3]::ModsFolderName)/$([TinyUIFixPSForTS3]::GeneratedPackageName)"
	static [Int32] $MaximumPatchsetConfigurationFileDepth = 90

	static [UInt32] $GroupID = 2223337553

	static [UInt32] $LAYOTypeID = 0x025c95b6
	static [UInt32] $_CSSTypeID = 0x025c90a6
	static [UInt32] $_XMLTypeID = 0x0333406c
	static [UInt32] $S3SATypeID = 0x073faa07

	static [String] $HexResourceKeyRegExPattern = '0x(?<ResourceType>[0-9A-Fa-f]{8})-0x(?<ResourceGroup>[0-9A-Fa-f]{8})-0x(?<Instance>[0-9A-Fa-f]{16})'

	static [RegEx] $GlobSegmentEscapeRegEx = [RegEx]::new('(\*+)|(\?+)|([^\*\?]+)', [Text.RegularExpressions.RegexOptions]::Compiled)

	static [RegEx[]] $PathDelimiterRegExes = @([RegEx]::new('/', [Text.RegularExpressions.RegexOptions]::Compiled), [RegEx]::new('[/\\]', [Text.RegularExpressions.RegexOptions]::Compiled))

	static [RegEx] $ResourceCFGLineRegEx = [RegEx]::new(
		'^\s*((?<Priority>Priority\s+(?<PriorityValue>-?[0-9]+))|(?<PackedFile>PackedFile\s+(?<PackedFileValue>\S.*)))\s*$',
		[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Compiled
	)


	static [PSCustomObject] ResolveResourcePriorities (
		[Collections.Generic.IEnumerable[ValueTuple[String, Int32]]] $PackedFileDirectives,
		[Collections.Generic.IEnumerable[String]] $FileNamesToIgnore,
		[IO.DirectoryInfo] $BaseDirectory,
		[Bool] $IsModDirectory,
		[Int32] $MinimumDepth
	)
	{
		return [TinyUIFixPSForTS3]::ResolveResourcePriorities($PackedFileDirectives, $FileNamesToIgnore, $BaseDirectory, $IsModDirectory, $MinimumDepth, $Script:IsWindows)
	}


	static [PSCustomObject] ResolveResourcePriorities (
		[Collections.Generic.IEnumerable[ValueTuple[String, Int32]]] $PackedFileDirectives,
		[Collections.Generic.IEnumerable[String]] $FileNamesToIgnore,
		[IO.DirectoryInfo] $BaseDirectory,
		[Bool] $IsModDirectory,
		[Int32] $MinimumDepth,
		[Bool] $BackslashAsPathDelimiter
	)
	{
		$Directives = [Linq.Enumerable]::OrderBy(
			$PackedFileDirectives,
			[Func[ValueTuple[String, Int32], String]] {Param ($D) $D.Item1},
			[StringComparer]::InvariantCultureIgnoreCase
		)

		$GreatestDepth = 0

		$DirectiveGlobs = foreach ($Directive in $Directives)
		{
			$Globs = [TinyUIFixPSForTS3]::ResolveResourceCFGGlobRelativity($Directive.Item1, $BackslashAsPathDelimiter, $MinimumDepth)

			if ($Null -eq $Globs) {continue}

			$GreatestDepth = if ($Globs.Count -gt $GreatestDepth) {$Globs.Count} else {$GreatestDepth}

			[ValueTuple[RegEx, UInt16, Int32]]::new(
				[RegEx]::new(
					"^$($Globs.GetEnumerator().ForEach{[TinyUIFixPSForTS3]::ResourceCFGGlobSegmentToRegExPattern($_)} -join '/')$",
					[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Compiled
				),
				[UInt16] ($Globs.Count - 1),
				$Directive.Item2
			)
		}

		$FilesByDepth = [Collections.Generic.Dictionary[Int32, [Collections.Generic.HashSet[String]]]]::new()

		$GetFiles = `
		{
			Param ([IO.DirectoryInfo] $Directory, [String] $Prefix, [Int32] $Depth)

			$Files = $FilesByDepth[$Depth]

			if ($Null -eq $Files)
			{
				$Files = [Collections.Generic.HashSet[String]]::new()
				$FilesByDepth[$Depth] = $Files
			}

			$Directory.EnumerateFileSystemInfos() | ForEach-Object `
			{
				if (($_.Attributes -band [IO.FileAttributes]::Directory) -eq 0)
				{
					$Files.Add($Prefix + $(if ($Prefix.Length -eq 0) {''} else {'/'}) + $_.Name)
				}
				elseif ($Depth -lt $GreatestDepth)
				{
					& $GetFiles $_ ($Prefix + $(if ($Prefix.Length -eq 0) {''} else {'/'}) + $_.Name) ($Depth + 1)
				}
			}
		}

		& $GetFiles $BaseDirectory '' 0

		$PrioritisedFiles = [Collections.Generic.Dictionary[UInt64, [Collections.Generic.List[String]]]]::new()
		$FilesExamined = [Collections.Generic.List[String]]::new()

		foreach ($DirectiveGlob in $DirectiveGlobs)
		{
			$RelevantFiles = $FilesByDepth[$DirectiveGlob.Item2]

			if ($Null -eq $RelevantFiles) {continue}

			foreach ($RelevantFile in $RelevantFiles.GetEnumerator())
			{
				if ($DirectiveGlob.Item1.IsMatch($RelevantFile))
				{
					$PriorityWithDepth = [TinyUIFixPSForTS3]::PackPriority($DirectiveGlob.Item3, $DirectiveGlob.Item2, $IsModDirectory)

					$Files = $PrioritisedFiles[$PriorityWithDepth]

					if ($Null -eq $Files)
					{
						$Files = [Collections.Generic.List[String]]::new()
						$PrioritisedFiles[$PriorityWithDepth] = $Files
					}

					$FilesExamined.Add($RelevantFile)

					if (-not [Linq.Enumerable]::Contains($FileNamesToIgnore, (Split-Path -Leaf $RelevantFile), [StringComparer]::InvariantCultureIgnoreCase))
					{
						$Files.Add($RelevantFile)
					}
				}
			}

			foreach ($ExaminedFile in $FilesExamined.GetEnumerator())
			{
				$RelevantFiles.Remove($ExaminedFile)
			}

			$FilesExamined.Clear()
		}

		foreach ($Files in $PrioritisedFiles.Values.GetEnumerator())
		{
			$Files.Sort([StringComparer]::InvariantCulture)
		}

		return [PSCustomObject] @{BaseDirectory = $BaseDirectory; PrioritisedFiles = $PrioritisedFiles}
	}


	static [UInt64] PackPriority ([Int32] $Priority, [UInt16] $Depth, [Bool] $IsMod)
	{
		return (
			     ([UInt64] $IsMod -shl 48) `
			-bor ([UInt64] ([Int64] $Priority - [Int32]::MinValue) -shl 16) `
			-bor [UInt64] $Depth
		)
	}


	static [ValueTuple[Int32, UInt16, Bool]] UnpackPriority ([UInt64] $Value)
	{
		return [ValueTuple[Int32, UInt16, Bool]]::new(
			[Int32] ([Int64] (($Value -shr 16) -band [UInt32]::MaxValue) + [Int32]::MinValue),
			[UInt16] ($Value -band [UInt16]::MaxValue),
			[Bool] (($Value -shr 48) -band 1)
		)
	}


	static [String] ResourceCFGGlobSegmentToRegExPattern ([String] $GlobSegment)
	{
		return [TinyUIFixPSForTS3]::GlobSegmentEscapeRegEx.Replace(
			$GlobSegment,
			[Text.RegularExpressions.MatchEvaluator] (
				{Param ($M) if ($M.Groups[1].Success) {'[^/]*'} elseif ($M.Groups[2].Success) {'[^/]'} else {[RegEx]::Escape($M.Value)}}
			)
		)
	}


	static [Collections.Generic.List[String]] ResolveResourceCFGGlobRelativity ([String] $Glob, [Bool] $BackslashAsPathDelimiter, [Int32] $MinimumDepth)
	{
		$Segments = [TinyUIFixPSForTS3]::PathDelimiterRegExes[$BackslashAsPathDelimiter].Split([String[]] $Glob, [StringSplitOptions]::None)
		$Resolved = [Collections.Generic.List[String]]::new($Segments.Length)
		$NegativeDepth = 0

		foreach ($Segment in $Segments)
		{
			if ($Segment -ceq '..')
			{
				if ($Resolved.Count - $NegativeDepth -gt 0)
				{
					$Resolved.RemoveAt($Resolved.Count - 1)
				}
				elseif (-$NegativeDepth -gt $MinimumDepth)
				{
					++$NegativeDepth
					$Resolved.Add($Segment)
				}
				else
				{
					return $Null
				}
			}
			elseif ($Segment -cne '.')
			{
				$Resolved.Add($Segment)
			}
		}

		return $Resolved
	}


	static [Collections.Generic.IEnumerable[ValueTuple[String, Int32]]] ExtractPackedFileDirectivesFromResourceCFG (
		[Collections.Generic.IEnumerable[String]] $CFGLines
	)
	{
		return [ValueTuple[String, Int32][]] (
			& `
			{
				$Priority = 0
				$Lines = $CFGLines.GetEnumerator()

				while ($Lines.MoveNext())
				{
					$Match = [TinyUIFixPSForTS3]::ResourceCFGLineRegEx.Match($Lines.Current)

					if ($Match.Success)
					{
						if (($Group = $Match.Groups['PriorityValue']).Success)
						{
							$Priority = [Int32] $Group.Value
						}
						elseif (($Group = $Match.Groups['PackedFileValue']).Success)
						{
							[ValueTuple[String, Int32]]::new($Group.Value, $Priority)
						}
					}
				}
			}
		)
	}


	static [Object] UseDisposable ([ScriptBlock] $MakeInputObject, [ScriptBlock] $Use)
	{
		$InputObject = $Null

		try
		{
			$InputObject = & $MakeInputObject

			$Result = & $Use $InputObject

			# Why must this language's implementation be so deficient?
			# See https://github.com/PowerShell/PowerShell/issues/7128
			if ($Null -eq $Result)
			{
				return $Null
			}
			else
			{
				return $Result
			}
		}
		catch
		{
			throw
		}
		finally
		{
			if ($Null -ne $InputObject)
			{
				$InputObject.Dispose()
			}
		}
	}


	static [Object] UseDisposable ([ScriptBlock] $MakeInputObject, [ScriptBlock] $Use, [ScriptBlock] $Dispose)
	{
		$InputObject = $Null

		try
		{
			$InputObject = & $MakeInputObject

			$Result = & $Use $InputObject

			# Why must this language's implementation be so deficient?
			# See https://github.com/PowerShell/PowerShell/issues/7128
			if ($Null -eq $Result)
			{
				return $Null
			}
			else
			{
				return $Result
			}
		}
		catch
		{
			throw
		}
		finally
		{
			if ($Null -ne $InputObject)
			{
				& $Dispose $InputObject
			}
		}
	}


	static [Object] MergeIntoDictionary ($Dictionary, $InputObject)
	{
		if ($InputObject -is [Collections.IDictionary])
		{
			foreach ($Entry in $InputObject.GetEnumerator())
			{
				$Dictionary[$Entry.Key] = $Entry.Value
			}
		}
		elseif ($InputObject -is [PSCustomObject])
		{
			foreach ($NoteProperty in (Get-Member -InputObject $InputObject -MemberType NoteProperty))
			{
				$Dictionary[$NoteProperty.Name] = $InputObject.($NoteProperty.Name)
			}
		}

		return $Dictionary
	}


	static [Object] RecursivelyMergeIntoDictionary ($Dictionary, $InputObject)
	{
		if ($InputObject -is [Collections.IDictionary])
		{
			foreach ($Entry in $InputObject.GetEnumerator())
			{
				if ($Entry.Value -is [Collections.IDictionary])
				{
					$ExistingValue = $Dictionary[$Entry.Key]

					if (-not ($ExistingValue -is [Collections.IDictionary]))
					{
						$ExistingValue = $Entry.Value.GetType()::new()
						$Dictionary[$Entry.Key] = $ExistingValue
					}

					[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary($ExistingValue, $Entry.Value)
				}
				elseif ($Entry.Value -is [PSCustomObject])
				{
					$ExistingValue = $Dictionary[$Entry.Key]

					if (-not ($ExistingValue -is [Collections.IDictionary]))
					{
						$ExistingValue = [Ordered] @{}
						$Dictionary[$Entry.Key] = $ExistingValue
					}

					[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary($ExistingValue, $Entry.Value)
				}
				else
				{
					$Dictionary[$Entry.Key] = $Entry.Value
				}
			}
		}
		elseif ($InputObject -is [PSCustomObject])
		{
			foreach ($NoteProperty in (Get-Member -InputObject $InputObject -MemberType NoteProperty))
			{
				if ($InputObject.($NoteProperty.Name) -is [Collections.IDictionary])
				{
					$ExistingValue = $Dictionary[$NoteProperty.Name]

					if (-not ($ExistingValue -is [Collections.IDictionary]))
					{
						$ExistingValue = $InputObject.($NoteProperty.Name).GetType()::new()
						$Dictionary[$NoteProperty.Name] = $ExistingValue
					}

					[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary($ExistingValue, $InputObject.($NoteProperty.Name))
				}
				elseif ($InputObject.($NoteProperty.Name) -is [PSCustomObject])
				{
					$ExistingValue = $Dictionary[$NoteProperty.Name]

					if (-not ($ExistingValue -is [Collections.IDictionary]))
					{
						$ExistingValue = [Ordered] @{}
						$Dictionary[$NoteProperty.Name] = $ExistingValue
					}

					[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary($ExistingValue, $InputObject.($NoteProperty.Name))
				}
				else
				{
					$Dictionary[$NoteProperty.Name] = $InputObject.($NoteProperty.Name)
				}
			}
		}

		return $Dictionary
	}

	static [HashTable] IndexBy ($Items, [ScriptBlock] $AsKey)
	{
		$Indexed = @{}

		foreach ($Item in $Items)
		{
			$Indexed[$Item.ForEach($AsKey)[0]] = $Item
		}

		return $Indexed
	}

	static [Void] WriteLineQuickly ([String] $Text)
	{
		if ($Script:NonInteractive)
		{
			Write-Host $Text
		}
		else
		{
			[Console]::WriteLine($Text)
		}
	}
}


if ($Script:MyInvocation.InvocationName -cne '.' -and $Script:MyInvocation.Line -cne '')
{
	$VersionString = "Version $([TinyUIFixPSForTS3]::Version)"

	$TL = [String] [Char] 9484
	$TR = [String] [Char] 9488
	$BL = [String] [Char] 9492
	$BR = [String] [Char] 9496
	$H = [String] [Char] 9472
	$V = [String] [Char] 9474

	[TinyUIFixPSForTS3]::WriteLineQuickly("$TL$($H * 28)$TR$([Environment]::NewLine)$V Tiny UI Fix for The Sims 3 $V$([Environment]::NewLine)$V $($VersionString.PadRight(26)) $V$([Environment]::NewLine)$BL$($H * 28)$BR")
}


if ($Null -eq $DBPFManipulationLibraryPath)
{
	if ($Null -eq $Script:ExpectedSims3Paths)
	{
		$Script:ExpectedSims3Paths = Get-ExpectedSims3Paths
	}
}


function Initialize-TinyUIFixResourceKeys
{
	$TinyUIFixPSForTS3ResourceKeys.UIDLL = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0xf7c3ade896d4e765 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.SimIFaceDLL = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0xc356df69b70add42 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.Sims3GameplaySystemsDLL = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0x03d6c8d903ce868c -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.Sims3GameplayObjectsDLL = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0xb9c90fdc6793bc0a -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.Sims3StoreObjectsDLL = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0x0cae1c361e05b2b3 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.StyleGuideLayout = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::LAYOTypeID, 0x00000000, 0x0a5e033d7797bde8 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3DLL = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0x9289ae008066179f -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3CoreBridge = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::S3SATypeID, 0x00000000, 0x50b4a8b4552640a5 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3XML = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::_XMLTypeID, 0x00000000, 0xfb0eb7b6db39b53f -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledVerticalScrollbarMimic = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::LAYOTypeID, [TinyUIFixPSForTS3]::GroupID -band [UInt32]::MaxValue, 0x81aef1dbd79895f8 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledHorizontalScrollbarMimic = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::LAYOTypeID, [TinyUIFixPSForTS3]::GroupID -band [UInt32]::MaxValue, 0xcd5e4225f2eec646 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledVerticalSliderMimic = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::LAYOTypeID, [TinyUIFixPSForTS3]::GroupID -band [UInt32]::MaxValue, 0x92e4874f8b9f3d39 -band [UInt64]::MaxValue)
	$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledHorizontalSliderMimic = [s3pi.Interfaces.TGIBlock]::new(1, $Null, [TinyUIFixPSForTS3]::LAYOTypeID, [TinyUIFixPSForTS3]::GroupID -band [UInt32]::MaxValue, 0xb30738093abb4eab -band [UInt64]::MaxValue)
}

if ($Null -ne ([Management.Automation.PSTypeName] 's3pi.Interfaces.TGIBlock').Type)
{
	Initialize-TinyUIFixResourceKeys
}


class TinyUIFixForTS3PatchsetDefinition
{
	static [RegEx] $ValidIDRegEx = [RegEx]::new('^(?!TinyUIFix)[A-Za-z][A-Za-z0-9_]+$', [Text.RegularExpressions.RegexOptions]::Compiled)

	[String] $FilePath
	[String] $ID
	[Version] $Version
	[Int32] $PatchsetDefinitionSchemaVersion
	[ScriptBlock] $ScriptBlock

	TinyUIFixForTS3PatchsetDefinition ([String] $FilePath, [String] $ID, [Version] $Version, [Int32] $PatchsetDefinitionSchemaVersion, [ScriptBlock] $ScriptBlock)
	{
		$This.FilePath = $FilePath
		$This.ID = $ID
		$This.Version = $Version
		$This.PatchsetDefinitionSchemaVersion = $PatchsetDefinitionSchemaVersion
		$This.ScriptBlock = $ScriptBlock
	}
}


class TinyUIFixForTS3Patchset
{
	static [Object] $MoreSettlingOfState = [Object]::new()

	[Object] $Instance
	[TinyUIFixForTS3PatchsetDefinition] $Definition

	TinyUIFixForTS3Patchset ([Object] $Instance, [TinyUIFixForTS3PatchsetDefinition] $Definition)
	{
		$This.Instance = $Instance
		$This.Definition = $Definition
	}
}


class TinyUIFixForTS3PatchsetLogger : TinyUIFixForTS3Logger
{
	hidden [TinyUIFixForTS3Patchset] $CurrentPatchset

	[Void] WriteWarning ([String] $Text)
	{
		([TinyUIFixForTS3Logger] $This).WriteWarning("Patchset/$($This.CurrentPatchset.Definition.ID)|v$($This.CurrentPatchset.Definition.Version): $Text")
	}

	[Void] WriteError ([String] $Text)
	{
		([TinyUIFixForTS3Logger] $This).WriteError("Patchset/$($This.CurrentPatchset.Definition.ID)|v$($This.CurrentPatchset.Definition.Version): $Text")
	}

	[Void] WriteInfo ([String] $Text)
	{
		([TinyUIFixForTS3Logger] $This).WriteInfo("Patchset/$($This.CurrentPatchset.Definition.ID)|v$($This.CurrentPatchset.Definition.Version): $Text")
	}

	TinyUIFixForTS3PatchsetLogger () : base()
	{}
}


function Find-ResourcesAcrossPackages (
	[Collections.Generic.Dictionary[UInt64, Collections.Generic.IEnumerable[Object]]] $PrioritisedFiles,
	[IO.DirectoryInfo] $BaseDirectory,
	[Collections.Generic.HashSet[s3pi.Interfaces.IResourceKey]] $ByKey,
	[UInt32[]] $ByResourceType,
	[ValueTuple[Object, Func[s3pi.Interfaces.IPackage, s3pi.Interfaces.IResourceKey, Bool]][]] $ByCondition
)
{
	[TinyUIFixForTS3Patcher.ResourceManipulator]::FindResourcesAcrossPackages(
		$PrioritisedFiles,
		$BaseDirectory,
		$ByKey,
		$ByResourceType,
		$ByCondition,
		[Delegate]::CreateDelegate([Func[Int32, String, Bool, s3pi.Interfaces.IPackage]], [s3pi.Package.Package].GetMethod('OpenPackage', [Type[]] @([Int32], [String], [Bool]))),
		[Delegate]::CreateDelegate([Action[Int32, s3pi.Interfaces.IPackage]], [s3pi.Package.Package].GetMethod('ClosePackage', [Type[]] @([Int32], [s3pi.Interfaces.IPackage]))),
		[Delegate]::CreateDelegate([Func[s3pi.Interfaces.IPackage, Collections.Generic.IEnumerable[s3pi.Interfaces.IResourceKey]]], [s3pi.Interfaces.IPackage].GetProperty('GetResourceList').GetMethod),
		[Delegate]::CreateDelegate([Func[s3pi.Interfaces.IResourceKey, UInt64]], [s3pi.Interfaces.IResourceKey].GetProperty('Instance').GetMethod),
		[Delegate]::CreateDelegate([Func[s3pi.Interfaces.IResourceKey, UInt32]], [s3pi.Interfaces.IResourceKey].GetProperty('ResourceType').GetMethod),
		[Delegate]::CreateDelegate([Func[s3pi.Interfaces.IResourceKey, UInt32]], [s3pi.Interfaces.IResourceKey].GetProperty('ResourceGroup').GetMethod),
		[Func[s3pi.Interfaces.IResourceKey, s3pi.Interfaces.TGIBlock]] {Param ($ResourceKey) [s3pi.Interfaces.TGIBlock]::new(1, $Null, $ResourceKey)},
		[Action[Exception]] {Param ($Exception) Write-Warning $Exception}
	)
}


function Resolve-ResourcePrioritiesForSims3Installation ([String] $Sims3Path, [String] $Sims3UserDataPath, [ScriptBlock] $TransformGameBinResourceCFG, [Switch] $IsMacOSInstallation, [Switch] $IncludeTinyUIFixPackage)
{
	[TinyUIFixPSForTS3]::WriteLineQuickly("Resolving the resource priorities for the Sims 3 installation at `"$Sims3Path`" with the user-data at `"$Sims3UserDataPath`".")

	$PrioritisedFiles = [Collections.Generic.Dictionary[UInt64, Collections.Generic.IEnumerable[Object]]]::new()

	$ResolveGameSubDirectory = `
	{
		Param ($SubPath, $Transform)

		$GameSubDirectory = Get-Item -LiteralPath (Join-Path $Sims3Path $SubPath) -ErrorAction Stop
		$GameSubPath = $GameSubDirectory.FullName
		$GameSubResourceCFGPath = Join-Path $GameSubDirectory.FullName Resource.cfg
		$GameSubResourceCFG = [String[]] (Get-Content -LiteralPath $GameSubResourceCFGPath -ErrorAction Stop)

		if ($Null -ne $Transform)
		{
			$GameSubResourceCFG = [String[]] (& $Transform $GameSubResourceCFG)
		}

		$GameSubPriorities = [TinyUIFixPSForTS3]::ResolveResourcePriorities(
			[TinyUIFixPSForTS3]::ExtractPackedFileDirectivesFromResourceCFG($GameSubResourceCFG),
			[String[]] @(),
			$GameSubDirectory,
			$False,
			-2
		)

		foreach ($Entry in $GameSubPriorities.PrioritisedFiles.GetEnumerator())
		{
			$PrioritisedFiles[$Entry.Key] = foreach ($File in $Entry.Value) {[IO.FileInfo] "$GameSubPath/$File"}
		}

		$GameSubDirectory
	}

	[TinyUIFixPSForTS3]::WriteLineQuickly("Checking the game folder at `"$Sims3Path`".")

	$GameSharedDirectory = & $ResolveGameSubDirectory $(if ($IsMacOSInstallation) {'Contents/GameData/Shared'} else {'GameData/Shared'})
	$GameBinDirectory = & $ResolveGameSubDirectory $(if ($IsMacOSInstallation) {'Contents/Resources'} else {'Game/Bin'}) $TransformGameBinResourceCFG

	$ExpectedModsDirectoryPath = Join-Path $Sims3UserDataPath Mods
	$ModsDirectory = Get-Item -LiteralPath $ExpectedModsDirectoryPath -ErrorAction Ignore
	$AllActiveModPackages = [Collections.Generic.List[String]]::new()

	$Result = [PSCustomObject] @{
		GameBinDirectory = $GameBinDirectory
		GameSharedDirectory = $GameSharedDirectory
		ModsDirectory = $ModsDirectory
		PrioritisedFiles = $PrioritisedFiles
		AllActiveModPackages = $AllActiveModPackages
	}

	if ($Null -eq $ModsDirectory)
	{
		Write-Warning "A `"Mods`" folder could not be found `"$ExpectedModsDirectoryPath`"." -WarningAction Continue

		return $Result
	}

	$ModsDirectoryPath = $ModsDirectory.FullName
	$ModsResourceCFGPath = Join-Path $ModsDirectory.FullName Resource.cfg

	if (-not (Test-Path -LiteralPath $ModsResourceCFGPath))
	{
		Write-Warning "A `"Resource.cfg`" file could not be found `"$ModsResourceCFGPath`"." -WarningAction Continue

		return $Result
	}

	$ModsResourceCFG = Get-Content -LiteralPath $ModsResourceCFGPath -ErrorAction Stop

	[TinyUIFixPSForTS3]::WriteLineQuickly("Checking the mods folder at `"$ModsDirectoryPath`".")

	$ModPriorities = [TinyUIFixPSForTS3]::ResolveResourcePriorities(
		[TinyUIFixPSForTS3]::ExtractPackedFileDirectivesFromResourceCFG([String[]] $ModsResourceCFG),
		[String[]] @($(if (-not $IncludeTinyUIFixPackage) {[TinyUIFixPSForTS3]::GeneratedPackageName})),
		$ModsDirectory,
		$True,
		0
	)

	foreach ($Entry in $ModPriorities.PrioritisedFiles.GetEnumerator())
	{
		$PrioritisedFiles[$Entry.Key] = @(
			foreach ($File in $Entry.Value)
			{
				$AllActiveModPackages.Add($File)
				[IO.FileInfo] "$ModsDirectoryPath/$File"
			}
		)
	}

	$Result
}


function Find-ResourcesToPatch ([PSCustomObject] $ResolvedResourcesPriorities)
{
	[TinyUIFixPSForTS3]::WriteLineQuickly("Finding UI resources to scale across $(($ResolvedResourcesPriorities.PrioritisedFiles.Values.ForEach{$_.Count} | Measure-Object -Sum).Sum) package files.")

	Find-ResourcesAcrossPackages `
		-PrioritisedFiles $ResolvedResourcesPriorities.PrioritisedFiles `
		-ByKey ([Collections.Generic.HashSet[s3pi.Interfaces.IResourceKey]]::new()) `
		-ByResourceType @([TinyUIFixPSForTS3]::LAYOTypeID, [TinyUIFixPSForTS3]::S3SATypeID, [TinyUIFixPSForTS3]::_CSSTypeID) `
		-ByCondition @()
}


function Group-ResourcesToPatchByPackage ([PSCustomObject] $ResourcesToPatch)
{
	$ResourcesByPackage = [Collections.Generic.Dictionary[String, Collections.Generic.Dictionary[s3pi.Interfaces.IResourceKey, Object]]]::new()

	$CategoriseResources = `
	{
		Param ($Category, $ResourcesByKey)

		foreach ($Entry in $ResourcesByKey.GetEnumerator())
		{
			$Resources = $ResourcesByPackage[$Entry.Value]

			if ($Null -eq $Resources)
			{
				$Resources = [Collections.Generic.Dictionary[s3pi.Interfaces.IResourceKey, Object]]::new()
				$ResourcesByPackage[$Entry.Value] = $Resources
			}

			$Resources[$Entry.Key] = $Category
		}
	}

	$CategorisedCount = ($ResourcesToPatch.ByKey.Values.ForEach{$_.Count} | Measure-Object -Sum).Sum
	[TinyUIFixPSForTS3]::WriteLineQuickly("Categorising $CategorisedCount resource$(if ($CategorisedCount -ne 1) {'s'}) by resource-key.")

	& $CategoriseResources ByKey $ResourcesToPatch.ByKey

	$CategorisedCount = ($ResourcesToPatch.ByResourceType.Values.ForEach{$_.Count} | Measure-Object -Sum).Sum
	[TinyUIFixPSForTS3]::WriteLineQuickly("Categorising $CategorisedCount resource$(if ($CategorisedCount -ne 1) {'s'}) by resource-type.")

	foreach ($ResourceType in $ResourcesToPatch.ByResourceType.GetEnumerator())
	{
		& $CategoriseResources $ResourceType.Key $ResourceType.Value
	}

	$CategorisedCount = ($ResourcesToPatch.ByCondition.Values.ForEach{$_.Count} | Measure-Object -Sum).Sum
	[TinyUIFixPSForTS3]::WriteLineQuickly("Categorising $CategorisedCount resource$(if ($CategorisedCount -ne 1) {'s'}) by condition.")

	foreach ($Condition in $ResourcesToPatch.ByCondition.GetEnumerator())
	{
		& $CategoriseResources $Condition.Key $Condition.Value
	}

	$ResourcesByPackage
}



function Find-InstanceField ([Mono.Cecil.TypeDefinition] $Type, [String] $Name)
{
	$Type.Fields.Where({-not $_.IsStatic -and $_.Name -ceq $Name}, 'First')[0]
}

function Find-StaticField ([Mono.Cecil.TypeDefinition] $Type, [String] $Name)
{
	$Type.Fields.Where({$_.IsStatic -and $_.Name -ceq $Name}, 'First')[0]
}

function Find-InstanceMethod ([Mono.Cecil.TypeDefinition] $Type, [String] $Name, [String[]] $ParameterTypes)
{
	$Type.Methods.Where({-not $_.IsStatic -and $_.Parameters.Count -eq $ParameterTypes.Count -and $_.Name -ceq $Name -and ($_.Parameters.Count -eq 0 -or [Linq.Enumerable]::SequenceEqual([String[]] $_.Parameters.ParameterType.FullName, $ParameterTypes))}, 'First')[0]
}

function Find-StaticMethod ([Mono.Cecil.TypeDefinition] $Type, [String] $Name, [String[]] $ParameterTypes)
{
	$Type.Methods.Where({$_.IsStatic -and $_.Parameters.Count -eq $ParameterTypes.Count -and $_.Name -ceq $Name -and ($_.Parameters.Count -eq 0 -or [Linq.Enumerable]::SequenceEqual([String[]] $_.Parameters.ParameterType.FullName, $ParameterTypes))}, 'First')[0]
}

function Find-InstanceProperty ([Mono.Cecil.TypeDefinition] $Type, [String] $Name)
{
	$Type.Properties.Where({-not $_.IsStatic -and $_.Name -ceq $Name}, 'First')[0]
}

function Find-StaticProperty ([Mono.Cecil.TypeDefinition] $Type, [String] $Name)
{
	$Type.Properties.Where({$_.IsStatic -and $_.Name -ceq $Name}, 'First')[0]
}


function Test-TypeDerivesFrom ([Mono.Cecil.TypeReference] $Type, $FullNameOfType)
{
	$ResolvedCurrentType = $Type.Resolve()

	for (;;)
	{
		if ($Null -eq $ResolvedCurrentType.BaseType)
		{
			return $False
		}

		$ResolvedCurrentType = $ResolvedCurrentType.BaseType.Resolve()

		if ($ResolvedCurrentType.FullName -ceq $FullNameOfType)
		{
			return $True
		}
	}
}

function Test-TypeIsOrDerivesFrom ([Mono.Cecil.TypeReference] $Type, $FullNameOfType)
{
	if ($Type.FullName -ceq $FullNameOfType)
	{
		return $True
	}

	Test-TypeDerivesFrom $Type $FullNameOfType
}


function Find-Returns ($InputObject)
{
	$InputObject.Body.Instructions.Where{$_.Opcode.Code -eq [Mono.Cecil.Cil.Code]::Ret}
}

function Test-IsTerminalConstructor ([Mono.Cecil.MethodDefinition] $Method)
{
	     $Method.Name -ceq '.ctor' `
	-and (
		$Method.Body.Instructions.Where(
			{$_.Opcode.Code -eq [Mono.Cecil.Cil.Code]::Call -and $_.Operand.DeclaringType -eq $Method.DeclaringType -and $_.Operand.Name -ceq '.ctor'},
			'First'
		).Count -eq 0
	)
}

function Select-TerminalConstructorsOfType ([Mono.Cecil.TypeDefinition] $Type)
{
	$Type.Methods | ? {Test-IsTerminalConstructor $_}
}


function Edit-MethodBody ([Mono.Cecil.MethodDefinition] $Method, [ScriptBlock] $Edit, [Switch] $DoNotOptimise, [Switch] $InitiallyReadOnly, [Switch] $ReturnResult)
{
	$IsReadOnly = $InitiallyReadOnly.IsPresent
	$IsReadOnlyReference = @($IsReadOnly)
	$IL = $Method.Body.GetILProcessor()

	if (-not $IsReadOnly -and -not $DoNotOptimise)
	{
		[Mono.Cecil.Rocks.MethodBodyRocks]::SimplifyMacros($IL.Body)
	}

	$StartOfIL = $IL.Body.Instructions[0]
	$Instruction = $StartOfIL
	$Returns = Find-Returns $IL

	$StartWriting = `
	{
		Set-Variable IsReadOnly $False -Scope 1
		Set-Variable StartOfIL $IL.Body.Instructions[0] -Scope 1
		Set-Variable Instruction $StartOfIL -Scope 1
		Set-Variable Returns (Find-Returns $IL) -Scope 1
		$IsReadOnlyReference[0] = $False
	}

	$Result = & $Edit -IL $IL -StartOfIL $StartOfIL -Returns $Returns -StartWriting $StartWriting

	if (-not $IsReadOnlyReference[0] -and -not $DoNotOptimise)
	{
		if ($InitiallyReadOnly)
		{
			[Mono.Cecil.Rocks.MethodBodyRocks]::SimplifyMacros($IL.Body)
		}

		[Mono.Cecil.Rocks.MethodBodyRocks]::OptimizeMacros($IL.Body)
		[Mono.Cecil.Rocks.MethodBodyRocks]::Optimize($IL.Body)
	}

	if ($ReturnResult)
	{
		$Result
	}
}


function Add-VariableToMethod ($InputObject, [Mono.Cecil.TypeReference] $Type)
{
	$Local = [Mono.Cecil.Cil.VariableDefinition]::new($Type)
	$InputObject.Body.Variables.Add($Local)

	$Local
}


function Find-PreviousInstruction ([Mono.Cecil.Cil.Instruction] $From, [UInt32] $AtMost = 1, [ScriptBlock] $Where)
{
	$Count = [UInt32] 0
	$Current = $From

	while ($Null -ne ($Current = $Current.Previous))
	{
		if ($Current.ForEach($Where))
		{
			$Current

			if ((++$Count) -ge $AtMost)
			{
				break
			}
		}
	}
}

function Find-NextInstruction ([Mono.Cecil.Cil.Instruction] $From, [UInt32] $AtMost = 1, [ScriptBlock] $Where)
{
	$Count = [UInt32] 0
	$Current = $From

	while ($Null -ne ($Current = $Current.Next))
	{
		if ($Current.ForEach($Where))
		{
			$Current

			if ((++$Count) -ge $AtMost)
			{
				break
			}
		}
	}
}


function Test-InstructionIsCall ([Mono.Cecil.Cil.Instruction] $Instruction, [Collections.Generic.IEnumerable[Mono.Cecil.MethodReference]] $OfAnyOf)
{
	if (
		    $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Call `
		-or $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Callvirt `
		-or $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Newobj
	)
	{
		$Target = $Instruction.Operand.FullName

		foreach ($Reference in $OfAnyOf)
		{
			if ($Target -ceq $Reference.FullName)
			{
				return $Reference
			}
		}
	}
}


$CompactLdcI4Codes = [Mono.Cecil.Cil.Code[]] @(
	[Mono.Cecil.Cil.Code]::Ldc_I4_M1
	[Mono.Cecil.Cil.Code]::Ldc_I4_0
	[Mono.Cecil.Cil.Code]::Ldc_I4_1
	[Mono.Cecil.Cil.Code]::Ldc_I4_2
	[Mono.Cecil.Cil.Code]::Ldc_I4_3
	[Mono.Cecil.Cil.Code]::Ldc_I4_4
	[Mono.Cecil.Cil.Code]::Ldc_I4_5
	[Mono.Cecil.Cil.Code]::Ldc_I4_6
	[Mono.Cecil.Cil.Code]::Ldc_I4_7
	[Mono.Cecil.Cil.Code]::Ldc_I4_8
)


function Test-InstructionIsLdcI4 ([Mono.Cecil.Cil.Instruction] $Instruction, [Int32[]] $OfAnyOf)
{
	$Code = $Instruction.OpCode.Code

	if ($Code -eq [Mono.Cecil.Cil.Code]::Ldc_I4 -or $Code -eq [Mono.Cecil.Cil.Code]::Ldc_I4_S)
	{
		if ($Null -ne $OfAnyOf.Where({$_ -eq $Instruction.Operand}, 'First')[0])
		{
			return $Instruction
		}
	}
	else
	{
		foreach ($Value in $OfAnyOf)
		{
			if ($Value -ge -1 -and $Value -le 8 -and $Code -eq $CompactLdcI4Codes[$Value + 1])
			{
				return $Instruction
			}
		}
	}
}


function Append-Instruction
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)] [Mono.Cecil.Cil.Instruction] $To,
		[Parameter(Mandatory)] [Mono.Cecil.Cil.ILProcessor] $IL,
		[Parameter(Mandatory, ValueFromPipeline)] [Mono.Cecil.Cil.Instruction] $InputObject
	)

	Begin
	{
		$LastInstruction = $To
	}

	Process
	{
		$IL.InsertAfter($LastInstruction, $InputObject)
		$LastInstruction = $InputObject
	}

	End
	{
		$LastInstruction
	}
}


function Apply-PatchToTinyUIFixForTS3Assembly ([Mono.Cecil.AssemblyDefinition] $Assembly, [Float] $UIScale)
{
	$UIScalingType = $Assembly.MainModule.GetType('TinyUIFixForTS3.UIScaling')
	$GetUIScale = Find-StaticMethod $UIScalingType GetUIScale

	Edit-MethodBody $GetUIScale `
	{
		foreach ($Instruction in $IL.Body.Instructions)
		{
			if ($Instruction.Opcode.Code -eq [Mono.Cecil.Cil.Code]::Ldc_R4)
			{
				$Instruction.Operand = [Float] $UIScale
			}
		}
	}
}


function Import-ReferenceIfNeeded ([Mono.Cecil.MemberReference] $Type, [Mono.Cecil.ModuleDefinition] $ForModule)
{
	if ($Type.Module -eq $ForModule)
	{
		$Type
	}
	else
	{
		$ForModule.Import($Type)
	}
}


function New-ParameterDefinition ($Signature, [Mono.Cecil.ModuleDefinition] $ForModule)
{
	$ParameterName = $Null
	$ParameterAttributes = [Mono.Cecil.ParameterAttributes]::None

	if ($Signature -is [Mono.Cecil.TypeReference])
	{
		$ParameterType = $Signature
	}
	elseif ($Signature.Count -eq 2)
	{
		if ($Signature[1] -is [String])
		{
			$ParameterName = $Signature[1]
			$ParameterType = $Signature[0]
		}
		else
		{
			$ParameterAttributes = $Signature[0]
			$ParameterType = $Signature[1]
		}
	}
	elseif ($Signature.Count -eq 3)
	{
		$ParameterAttributes = $Signature[0]
		$ParameterType = $Signature[1]
		$ParameterName = $Signature[2]
	}

	[Mono.Cecil.ParameterDefinition]::new($ParameterName, $ParameterAttributes, (Import-ReferenceIfNeeded $ParameterType $ForModule))
}


function New-DelegateTypeDefinition (
	[Mono.Cecil.ModuleDefinition] $ForModule,
	[Mono.Cecil.AssemblyDefinition] $MSCorLib,
	$Namespace,
	[String] $Name,
	[Mono.Cecil.TypeAttributes] $Attributes,
	[Mono.Cecil.TypeReference] $ReturnType,
	[Object[]] $ParameterTypes,
	[Switch] $Multicast = $True
)
{
	$Import = if ($ForModule -eq $MSCorLib) {{Param ($D) $D}} else {{Param ($D) $ForModule.Import($D)}}

	$AsyncCallbackType = $MSCorLib.MainModule.GetType('System.AsyncCallback')
	$IAsyncResultType = $MSCorLib.MainModule.GetType('System.IAsyncResult')
	$IntPtrType = $MSCorLib.MainModule.GetType('System.IntPtr')
	$BaseType = $MSCorLib.MainModule.GetType($(if ($Multicast) {'System.MulticastDelegate'} else {'System.Delegate'}))
	$ObjectType = $MSCorLib.MainModule.GetType('System.Object')

	$Type = [Mono.Cecil.TypeDefinition]::new($Namespace, $Name, [Mono.Cecil.TypeAttributes]::Sealed -bor $Attributes)
	$Type.BaseType = (& $Import $BaseType)

	$Ctor = [Mono.Cecil.MethodDefinition]::new(
		'.ctor',
		[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
		$ForModule.TypeSystem.Void
	)
	$Ctor.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::Runtime
	$Ctor.Parameters.Add([Mono.Cecil.ParameterDefinition]::new('object', [Mono.Cecil.ParameterAttributes]::None, $ForModule.TypeSystem.Object))
	$Ctor.Parameters.Add([Mono.Cecil.ParameterDefinition]::new('method', [Mono.Cecil.ParameterAttributes]::None, $ForModule.TypeSystem.IntPtr))
	$Type.Methods.Add($Ctor)

	$Invoke = [Mono.Cecil.MethodDefinition]::new(
		'Invoke',
		[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Virtual -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::VtableLayoutMask,
		(Import-ReferenceIfNeeded $ReturnType $ForModule)
	)
	$Invoke.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::Runtime

	$AddParametersTo = `
	{
		Param ($Method)

		foreach ($ParameterType in $ParameterTypes)
		{
			$Method.Parameters.Add((New-ParameterDefinition $ParameterType $ForModule))
		}
	}

	& $AddParametersTo $Invoke

	$Type.Methods.Add($Invoke)

	$BeginInvoke = [Mono.Cecil.MethodDefinition]::new(
		'BeginInvoke',
		[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Virtual -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::VtableLayoutMask,
		(& $Import $IAsyncResultType)
	)
	$BeginInvoke.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::Runtime
	$BeginInvoke.Parameters.Add([Mono.Cecil.ParameterDefinition]::new('callback', [Mono.Cecil.ParameterAttributes]::None, (& $Import $AsyncCallbackType)))
	$BeginInvoke.Parameters.Add([Mono.Cecil.ParameterDefinition]::new('object', [Mono.Cecil.ParameterAttributes]::None, $ForModule.TypeSystem.Object))

	& $AddParametersTo $BeginInvoke

	$Type.Methods.Add($BeginInvoke)

	$EndInvoke = [Mono.Cecil.MethodDefinition]::new(
		'EndInvoke',
		[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Virtual -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::VtableLayoutMask,
		(Import-ReferenceIfNeeded $ReturnType $ForModule)
	)
	$EndInvoke.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::Runtime
	$EndInvoke.Parameters.Add([Mono.Cecil.ParameterDefinition]::new('result', [Mono.Cecil.ParameterAttributes]::None, (& $Import $IAsyncResultType)))
	$Type.Methods.Add($EndInvoke)

	$Type
}


function New-TinyUIFixForTS3IntegrationType ([String] $Namespace, [Mono.Cecil.ModuleDefinition] $ForModule)
{
	$MSCorLib = $ForModule.AssemblyResolver.Resolve($ForModule.AssemblyReferences.Where({$_.Name -ceq 'mscorlib'}, 'First')[0])

	$CompilerGeneratedAttributeType = $MSCorLib.MainModule.GetType('System.Runtime.CompilerServices.CompilerGeneratedAttribute')

	$CompilerGeneratedAttributeCtor = Find-InstanceMethod $CompilerGeneratedAttributeType .ctor
	$ObjectCtor = Find-InstanceMethod $MSCorLib.MainModule.GetType('System.Object') .ctor

	$TinyUIFixForTS3IntegrationType = [Mono.Cecil.TypeDefinition]::new(
		$Namespace,
		'TinyUIFixForTS3Integration',
		[Mono.Cecil.TypeAttributes]::Public -bor [Mono.Cecil.TypeAttributes]::Abstract -bor [Mono.Cecil.TypeAttributes]::Sealed -bor [Mono.Cecil.TypeAttributes]::BeforeFieldInit
	)

	$TinyUIFixForTS3IntegrationType.BaseType = $ForModule.TypeSystem.Object

	$FloatGetterType = New-DelegateTypeDefinition $ForModule $MSCorLib $Null FloatGetter ([Mono.Cecil.TypeAttributes]::NestedPublic) $ForModule.TypeSystem.Single

	$TinyUIFixForTS3IntegrationType.NestedTypes.Add($FloatGetterType)

	${<>cType} = [Mono.Cecil.TypeDefinition]::new(
		$Null,
		'<>c',
		[Mono.Cecil.TypeAttributes]::NestedPrivate -bor [Mono.Cecil.TypeAttributes]::Sealed -bor [Mono.Cecil.TypeAttributes]::Serializable -bor [Mono.Cecil.TypeAttributes]::BeforeFieldInit
	)
	${<>cType}.BaseType = $ForModule.TypeSystem.Object
	${<>cType}.CustomAttributes.Add([Mono.Cecil.CustomAttribute]::new($ForModule.Import($CompilerGeneratedAttributeCtor)))

	${<>c<>9} = [Mono.Cecil.FieldDefinition]::new(
		'<>9',
		[Mono.Cecil.FieldAttributes]::Public.value__ -bor [Mono.Cecil.FieldAttributes]::Static -bor [Mono.Cecil.FieldAttributes]::InitOnly,
		${<>cType}
	)
	${<>cType}.Fields.Add(${<>c<>9})

	${<>c.ctor} = [Mono.Cecil.MethodDefinition]::new(
		'.ctor',
		[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
		$ForModule.TypeSystem.Void
	)
	${<>c.ctor}.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::IL
	${<>c.ctor}.Body = [Mono.Cecil.Cil.MethodBody]::new(${<>c.ctor})

	Edit-MethodBody ${<>c.ctor} `
	{
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Call, $ForModule.Import($ObjectCtor))
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
	} > $Null

	${<>cType}.Methods.Add(${<>c.ctor})

	${<>c.cctor} = [Mono.Cecil.MethodDefinition]::new(
		'.cctor',
		[Mono.Cecil.MethodAttributes]::Private.value__ -bor [Mono.Cecil.MethodAttributes]::Static -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
		$ForModule.TypeSystem.Void
	)
	${<>c.cctor}.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::IL
	${<>c.cctor}.Body = [Mono.Cecil.Cil.MethodBody]::new(${<>c.cctor})

	Edit-MethodBody ${<>c.cctor} `
	{
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, ${<>c.ctor})
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stsfld, ${<>c<>9})
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
	} > $Null

	${<>cType}.Methods.Add(${<>c.cctor})

	${<>c<.cctor>b__2_0} = [Mono.Cecil.MethodDefinition]::new(
		'<.cctor>b__2_0',
		[Mono.Cecil.MethodAttributes]::Assembly.value__ -bor [Mono.Cecil.MethodAttributes]::HideBySig,
		$ForModule.TypeSystem.Single
	)
	${<>c<.cctor>b__2_0}.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::IL
	${<>c<.cctor>b__2_0}.Body = [Mono.Cecil.Cil.MethodBody]::new(${<>c<.cctor>b__2_0})

	Edit-MethodBody ${<>c<.cctor>b__2_0} `
	{
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [Float] 1)
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
	} > $Null

	${<>cType}.Methods.Add(${<>c<.cctor>b__2_0})

	$TinyUIFixForTS3IntegrationType.NestedTypes.Add(${<>cType})

	$TinyUIFixForTS3IntegrationGetUIScale = [Mono.Cecil.FieldDefinition]::new(
		'getUIScale',
		[Mono.Cecil.FieldAttributes]::Public.value__ -bor [Mono.Cecil.FieldAttributes]::Static,
		$FloatGetterType
	)
	$TinyUIFixForTS3IntegrationType.Fields.Add($TinyUIFixForTS3IntegrationGetUIScale)

	$TinyUIFixForTS3IntegrationCCtor = [Mono.Cecil.MethodDefinition]::new(
		'.cctor',
		[Mono.Cecil.MethodAttributes]::Private.value__ -bor [Mono.Cecil.MethodAttributes]::Static -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
		$ForModule.TypeSystem.Void
	)
	$TinyUIFixForTS3IntegrationCCtor.ImplAttributes = [Mono.Cecil.MethodImplAttributes]::IL
	$TinyUIFixForTS3IntegrationCCtor.Body = [Mono.Cecil.Cil.MethodBody]::new($TinyUIFixForTS3IntegrationCCtor)

	Edit-MethodBody $TinyUIFixForTS3IntegrationCCtor `
	{
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldsfld, ${<>c<>9})
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldftn, ${<>c<.cctor>b__2_0})
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, (Find-InstanceMethod $FloatGetterType .ctor System.Object, System.IntPtr))
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stsfld, $TinyUIFixForTS3IntegrationGetUIScale)
		$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
	} > $Null

	$TinyUIFixForTS3IntegrationType.Methods.Add($TinyUIFixForTS3IntegrationCCtor)

	$TinyUIFixForTS3IntegrationType
}


function Apply-PatchesToResources (
	[PSCustomObject] $UnpatchedResources,
	$UnpatchedResourcesByPackage,
	$State,
	$OutputUnpackedAssemblyDirectoryPath,
	[Switch] $Uncompressed
)
{
	$State.UnpatchedResources = $UnpatchedResources
	$State.UnpatchedResourcesByPackage = $UnpatchedResourcesByPackage

	$Patchsets = [Object[]] $State.Patchsets.Values
	$PatchsetsRetro = [Object[]]::new($Patchsets.Length)
	[Object[]]::Copy($Patchsets, $PatchsetsRetro, $PatchsetsRetro.Length)
	[Object[]]::Reverse($PatchsetsRetro)


	foreach ($Patchset in $Patchsets)
	{
		if ($Patchset.Instance.InitialiseBeforePatching -is [ScriptBlock])
		{
			[TinyUIFixPSForTS3]::WriteLineQuickly("Initialising the `"$($Patchset.Definition.ID)`" patchset after loading it.")

			$State.Logger.CurrentPatchset = $Patchset
			& $Patchset.Instance.InitialiseBeforePatching -Self $Patchset.Instance -State $State > $Null
		}
	}


	foreach ($Patchset in $Patchsets)
	{
		if ($Null -ne $Patchset.Instance.BeforeUIScaling)
		{
			if ($Patchset.Instance.BeforeUIScaling.ApplyPatch -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Applying the BeforeUIScaling patch from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $Patchset.Instance.BeforeUIScaling.ApplyPatch -Self $Patchset.Instance -State $State > $Null
			}
		}
	}

	foreach ($Patchset in $PatchsetsRetro)
	{
		if ($Null -ne $Patchset.Instance.BeforeUIScaling)
		{
			if ($Patchset.Instance.BeforeUIScaling.ApplyPatchRetro -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Applying the BeforeUIScaling retro-patch from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $Patchset.Instance.BeforeUIScaling.ApplyPatchRetro -Self $Patchset.Instance -State $State > $Null
			}
		}
	}

	$State.RegisteredExtraLayoutScalers = [Collections.Generic.List[TinyUIFixForTS3Patcher.LayoutScaler+ExtraScaler]]::new(0)

	$HandleSuppliedExtraLayoutScalers = `
	{
		Param ($ExtraScalers)

		if ($Null -ne $ExtraScalers)
		{
			$State.RegisteredExtraLayoutScalers.AddRange([TinyUIFixForTS3Patcher.LayoutScaler+ExtraScaler[]] $ExtraScalers)
		}
	}

	foreach ($Patchset in $Patchsets)
	{
		if ($Null -ne $Patchset.Instance.DuringUIScaling)
		{
			if ($Patchset.Instance.DuringUIScaling.SupplyExtraLayoutScalers -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Getting extra layout-scalers from the `"$($Patchset.Definition.ID)`" patchset.")

				& $HandleSuppliedExtraLayoutScalers $(
					$State.Logger.CurrentPatchset = $Patchset
					& $Patchset.Instance.DuringUIScaling.SupplyExtraLayoutScalers -Self $Patchset.Instance -State $State
				)
			}
		}
	}

	foreach ($Patchset in $PatchsetsRetro)
	{
		if ($Null -ne $Patchset.Instance.DuringUIScaling)
		{
			if ($Patchset.Instance.DuringUIScaling.SupplyExtraLayoutScalersRetro -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Getting extra layout-scalers, retro, from the `"$($Patchset.Definition.ID)`" patchset.")

				& $HandleSuppliedExtraLayoutScalers $(
					$State.Logger.CurrentPatchset = $Patchset
					& $Patchset.Instance.DuringUIScaling.SupplyExtraLayoutScalersRetro -Self $Patchset.Instance -State $State
				)
			}
		}
	}


	$ResourcesByPackage = $UnpatchedResourcesByPackage


	$AssemblyStreams = [Collections.Generic.Dictionary[s3pi.Interfaces.TGIBlock, IO.MemoryStream]]::new(8)

	$AddAssemblyStream = `
	{
		Param ($Package, $IndexEntry)

		$Stream = [IO.MemoryStream]::new()

		[s3pi.WrapperDealer.WrapperDealer]::GetResource(1, $Package, $IndexEntry).Assembly.BaseStream.CopyTo($Stream)
		$Stream.Position = 0

		$ResourceKey = [s3pi.Interfaces.TGIBlock]::new(1, $Null, $IndexEntry)
		$AssemblyStreams[$ResourceKey] = $Stream
	}

	[TinyUIFixPSForTS3]::WriteLineQuickly('Extracting assemblies.')

	foreach ($Entry in $ResourcesByPackage.GetEnumerator())
	{
		[TinyUIFixPSForTS3]::UseDisposable(
			{[s3pi.Package.Package]::OpenPackage(1, $Entry.Key)},
			{
				Param ($Package)

				foreach ($IndexEntry in $Package.GetResourceList.GetEnumerator())
				{
					if ($IndexEntry.ResourceType -ceq [TinyUIFixPSForTS3]::S3SATypeID)
					{
						& $AddAssemblyStream $Package $IndexEntry
					}
				}
			},
			{Param ($Package) [s3pi.Package.Package]::ClosePackage(1, $Package)}
		)
	}

	[TinyUIFixPSForTS3]::WriteLineQuickly("Extracted $($AssemblyStreams.Count) assembl$(if ($AssemblyStreams.Count -ne 1) {'ies'} else {'y'}).")


	$UTF8 = [Text.UTF8Encoding]::new($False, $False)

	$EditXMLResource = `
	{
		Param ([s3pi.Interfaces.IResourceIndexEntry] $IndexEntry, [s3pi.Package.Package] $FromPackage, [ScriptBlock] $Edit)

		$XMLResource = [s3pi.WrapperDealer.WrapperDealer]::GetResource(1, $FromPackage, $IndexEntry)
		$XML = [Xml.XmlDocument]::new()
		$XML.Load($XMLResource.Stream)

		if (-not (& $Edit $XML))
		{
			return $Null
		}

		$NewXMLResource = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::LAYOTypeID)

		$Settings = [Xml.XmlWriterSettings]::new()
		$Settings.Indent = $True
		$Settings.IndentChars = "`t"
		$Settings.NewLineChars = "`r`n"
		$Settings.Encoding = $UTF8

		[TinyUIFixPSForTS3]::UseDisposable(
			{[Xml.XmlWriter]::Create($NewXMLResource.Stream, $Settings)},
			{Param ($Writer) $XML.Save($Writer)}
		) > $Null
		$XML = $Null
		$State.IntoPackage.AddResource($IndexEntry, $NewXMLResource.Stream, $False)
	}


	$WinProcLayoutWinProcsByControlID = [Collections.Generic.Dictionary[UInt32, Collections.Generic.List[ValueTuple[TinyUIFixForTS3Patcher.LayoutScaler+LayoutWinProc, TinyUIFixForTS3Patcher.LayoutScaler+ControlIDChain]]]]::new()


	$ScaledCounts = [UInt32[]] @(0, 0, 0)

	$ApplyPatch = `
	{
		Param ($Category, [s3pi.Interfaces.IResourceIndexEntry] $IndexEntry, [s3pi.Package.Package] $FromPackage, $PackageSource)

		if ($Category -ceq [TinyUIFixPSForTS3]::LAYOTypeID)
		{
			& $EditXMLResource $IndexEntry $FromPackage `
			{
				Param ($XML)

				$StyleGuideLayoutResourceKey = $TinyUIFixPSForTS3ResourceKeys.StyleGuideLayout

				if (
					     $StyleGuideLayoutResourceKey.Instance -eq $IndexEntry.Instance `
					-and $StyleGuideLayoutResourceKey.ResourceType -eq $IndexEntry.ResourceType `
					-and $StyleGuideLayoutResourceKey.ResourceGroup -eq $IndexEntry.ResourceGroup
				)
				{
					return $False
				}

				try
				{
					$Result = [TinyUIFixForTS3Patcher.LayoutScaler]::ScaleLayoutBy($XML, $State.Configuration.Nucleus.UIScale, $State.RegisteredExtraLayoutScalers)
				}
				catch
				{
					Write-Warning "An error occurred when scaling the layout with a resource-key of $IndexEntry, from the package at $PackageSource.$([Environment]::NewLine)The error was:$([Environment]::NewLine)$($_.Exception)" -WarningAction Continue

					return $False
				}

				foreach ($LayoutWinProcs in $Result.scrollbarLayoutWinProcsByControlID, $Result.sliderLayoutWinProcsByControlID)
				{
					foreach ($WinProcLayoutsByControlID in $LayoutWinProcs.GetEnumerator())
					{
						$WinProcLayouts = $Null

						if (-not $WinProcLayoutWinProcsByControlID.TryGetValue($WinProcLayoutsByControlID.Key, [Ref] $WinProcLayouts))
						{
							$WinProcLayouts = [Collections.Generic.List[ValueTuple[TinyUIFixForTS3Patcher.LayoutScaler+LayoutWinProc, TinyUIFixForTS3Patcher.LayoutScaler+ControlIDChain]]]::new()
							$WinProcLayoutWinProcsByControlID[$WinProcLayoutsByControlID.Key] = $WinProcLayouts
						}

						$WinProcLayouts.AddRange($WinProcLayoutsByControlID.Value)
					}
				}

				$True
			}

			1
		}
		elseif ($Category -ceq [TinyUIFixPSForTS3]::_CSSTypeID)
		{
			$StyleSheet = [s3pi.WrapperDealer.WrapperDealer]::GetResource(1, $FromPackage, $IndexEntry)
			$CSS = [IO.StreamReader]::new($StyleSheet.Stream, $UTF8).ReadToEnd()

			$CSS = [TinyUIFixForTS3Patcher.StyleSheetScaler]::ScaleStyleSheetBy($CSS, $State.Configuration.Nucleus.UIScale)

			$StyleSheet = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::_CSSTypeID)
			[IO.StreamWriter]::new($StyleSheet.Stream, $UTF8).Write($CSS)
			$CSS = $Null
			$State.IntoPackage.AddResource($IndexEntry, $StyleSheet.Stream, $False)

			2
		}
		else
		{
			$Null
			0
		}
	}

	if ($Null -ne $OutputUnpackedAssemblyDirectoryPath)
	{
		$OutputUnpackedAssemblyDirectory = New-Item -ItemType Directory -Force -Path $OutputUnpackedAssemblyDirectoryPath
	}

	$Resources = [Collections.Generic.List[ValueTuple[Object, s3pi.Interfaces.IResourceIndexEntry]]]::new()

	foreach ($Entry in $ResourcesByPackage.GetEnumerator())
	{
		[TinyUIFixPSForTS3]::UseDisposable(
			{[s3pi.Package.Package]::OpenPackage(1, $Entry.Key)},
			{
				Param ($Package)

				[TinyUIFixPSForTS3]::WriteLineQuickly("Scaling the resources of the package at `"$($Entry.Key)`".")

				$Resources.Clear()

				foreach ($IndexEntry in $Package.GetResourceList.GetEnumerator())
				{
					foreach ($CategorisedKey in $Entry.Value.GetEnumerator())
					{
						if (
							     $CategorisedKey.Key.Instance -eq $IndexEntry.Instance `
							-and $CategorisedKey.Key.ResourceType -eq $IndexEntry.ResourceType `
							-and $CategorisedKey.Key.ResourceGroup -eq $IndexEntry.ResourceGroup
						)
						{
							$Resources.Add([ValueTuple[Object, s3pi.Interfaces.IResourceIndexEntry]]::new($CategorisedKey.Value, $IndexEntry))

							$Entry.Value.Remove($CategorisedKey.Key)

							break
						}
					}
				}

				foreach ($Resource in $Resources.GetEnumerator())
				{
					$IndexEntry, $CountIndex = & $ApplyPatch $Resource.Item1 $Resource.Item2 -FromPackage $Package $Entry.Key

					if ($Null -ne $IndexEntry)
					{
						$IndexEntry.Compressed = if ($Uncompressed) {0} else {0xffff}
						$IndexEntry

						++$ScaledCounts[$CountIndex]
					}
				}
			},
			{Param ($Package) [s3pi.Package.Package]::ClosePackage(1, $Package)}
		)
	}

	[TinyUIFixPSForTS3]::WriteLineQuickly("Scaled $($ScaledCounts[1]) layout$(if ($ScaledCounts[1] -ne 1) {'s'}), and $($ScaledCounts[2]) CSS text-style$(if ($ScaledCounts[2] -ne 1) {'s'}).")


	[TinyUIFixPSForTS3]::WriteLineQuickly('Identifying layout-win-procs by control-ID.')

	$ControlIDChainLength = [UInt32] 1
	$WinProcLayoutsByControlIDChainLength = [Collections.Generic.Dictionary[UInt32, Collections.Generic.List[ValueTuple[TinyUIFixForTS3Patcher.LayoutScaler+LayoutWinProc, TinyUIFixForTS3Patcher.LayoutScaler+ControlIDChain]]]]::new()
	$BucketedControlIDs = [Collections.Generic.List[UInt32]]::new()

	while ($WinProcLayoutWinProcsByControlID.Count -gt 0)
	{
		$Bucket = [Collections.Generic.List[ValueTuple[TinyUIFixForTS3Patcher.LayoutScaler+LayoutWinProc, TinyUIFixForTS3Patcher.LayoutScaler+ControlIDChain]]]::new()
		$WinProcLayoutsByControlIDChainLength[$ControlIDChainLength] = $Bucket

		foreach ($WinProcLayoutsByControlID in $WinProcLayoutWinProcsByControlID.GetEnumerator())
		{
			if ($WinProcLayoutsByControlID.Value.Count -le 1)
			{
				$BucketedControlIDs.Add($WinProcLayoutsByControlID.Key)

				if ($WinProcLayoutsByControlID.Value.Count -gt 0)
				{
					$Bucket.Add($WinProcLayoutsByControlID.Value[0])
				}
			}
		}

		foreach ($ControlID in $BucketedControlIDs)
		{
			$WinProcLayoutWinProcsByControlID.Remove($ControlID)
		}

		$BucketedControlIDs.Clear()

		$WinProcLayouts = $WinProcLayoutWinProcsByControlID.Values.ForEach{$_}

		foreach ($ControlID in [Linq.Enumerable]::ToArray($WinProcLayoutWinProcsByControlID.Keys))
		{
			$WinProcLayoutWinProcsByControlID.Remove($ControlID)
		}

		foreach ($WinProcLayout in $WinProcLayouts)
		{
			if ($ControlIDChainLength -ge $WinProcLayout.Item2.controlIDs.Count)
			{
				Write-Warning "The control-ID-chain of [$($WinProcLayout.Item2.controlIDs -join ', ')] does not uniquely identify a WinProc with a layout win-proc, so some WinProcs may be incorrectly positioned."
			}
			else
			{
				$WinProcLayoutWinProcsByControlID[$WinProcLayout.Item2.controlIDs[$WinProcLayout.Item2.controlIDs.Count - 1 - $ControlIDChainLength]] = $WinProcLayout
			}
		}

		++$ControlIDChainLength
	}


	$ReplaceableResourcesByKey = [Collections.Generic.Dictionary[s3pi.Interfaces.TGIBlock, s3pi.Interfaces.IResourceIndexEntry]]::new()

	foreach ($IndexEntry in $State.IntoPackage.GetResourceList.GetEnumerator())
	{
		$ReplaceableResourcesByKey[[s3pi.Interfaces.TGIBlock]::new(1, $Null, $IndexEntry)] = $IndexEntry
	}

	$HandleResourceReplacement = `
	{
		Param ($Replacements, $SourcePatchset)

		foreach ($Replacement in $Replacements.Resources)
		{
			$Key = [s3pi.Interfaces.TGIBlock]::new(1, $Null, $Replacement.ResourceKey.ResourceType, $Replacement.ResourceKey.ResourceGroup, $Replacement.ResourceKey.Instance)

			$IndexEntry = $Null

			if ($ReplaceableResourcesByKey.TryGetValue($Key, [Ref] $IndexEntry))
			{
				$State.IntoPackage.DeleteResource($IndexEntry)

				[TinyUIFixPSForTS3]::WriteLineQuickly("Replacing resource $Key with a resource from the `"$($SourcePatchset.Definition.ID)`" patchset.")
			}
			else
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Adding a resource, with the key $Key, from the `"$($SourcePatchset.Definition.ID)`" patchset.")
			}

			$IndexEntry = $State.IntoPackage.AddResource($Replacement.ResourceKey, $Replacement.Resource.Stream, $False)
			$IndexEntry.Compressed = if ($Uncompressed) {0} else {0xffff}
			$ReplaceableResourcesByKey[$Key] = $IndexEntry

			if ($Replacement.ResourceKey.ResourceType -eq [TinyUIFixPSForTS3]::S3SATypeID)
			{
				& $AddAssemblyStream $State.IntoPackage $IndexEntry
			}
		}
	}

	foreach ($Patchset in $Patchsets)
	{
		if ($Null -ne $Patchset.Instance.DuringUIScaling)
		{
			if ($Patchset.Instance.DuringUIScaling.ReplaceResources -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Replacing resources with those from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $HandleResourceReplacement (& $Patchset.Instance.DuringUIScaling.ReplaceResources -Self $Patchset.Instance -State $State) $Patchset
			}
		}
	}

	foreach ($Patchset in $PatchsetsRetro)
	{
		if ($Null -ne $Patchset.Instance.DuringUIScaling)
		{
			if ($Patchset.Instance.DuringUIScaling.ReplaceResourcesRetro -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Replacing resources with those, retro, from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $HandleResourceReplacement (& $Patchset.Instance.DuringUIScaling.ReplaceResourcesRetro -Self $Patchset.Instance -State $State) $Patchset
			}
		}
	}


	$AssemblyResolver = [TinyUIFixForTS3Patcher.AssemblyScaling+PrimitiveAssemblyResolver]::new()
	$AssemblyKeysByResourceKey = [Collections.Generic.Dictionary[s3pi.Interfaces.TGIBlock, ValueTuple[String, Version]]]::new($AssemblyStreams.Count)
	$ResourceKeysByAssemblyKey = [Collections.Generic.Dictionary[ValueTuple[String, Version], s3pi.Interfaces.TGIBlock]]::new($AssemblyStreams.Count)
	$ResourceKeysByAssembly = [Collections.Generic.Dictionary[Mono.Cecil.AssemblyDefinition, s3pi.Interfaces.TGIBlock]]::new($AssemblyStreams.Count)

	[TinyUIFixPSForTS3]::WriteLineQuickly("Resolving $($AssemblyStreams.Count) assembl$(if ($AssemblyStreams.Count -ne 1) {'ies'} else {'y'}).")

	foreach ($AssemblyStream in $AssemblyStreams.GetEnumerator())
	{
		$ReaderParameters = [Mono.Cecil.ReaderParameters]::new()
		$ReaderParameters.AssemblyResolver = $AssemblyResolver
		$Assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($AssemblyStream.Value, $ReaderParameters)
		$AssemblyKey = $AssemblyResolver.Add($Assembly)
		$AssemblyKeysByResourceKey[$AssemblyStream.Key] = $AssemblyKey
		$ResourceKeysByAssemblyKey[$AssemblyKey] = $AssemblyStream.Key
		$ResourceKeysByAssembly[$Assembly] = $AssemblyStream.Key
	}

	[TinyUIFixPSForTS3]::WriteLineQuickly("$(if ($AssemblyResolver.assemblies.Count -ne 1) {"These $($AssemblyResolver.assemblies.Count) assemblies were"} else {'This assembly was'}) resolved: $(($AssemblyResolver.assemblies.Values.ForEach{$_.Name.Name.Replace('\', '\\').Replace(';', '\;')} | Sort-Object) -join '; ').")

	$State.Assemblies = [PSCustomObject] @{Resolver = $AssemblyResolver; AssemblyKeysByResourceKey = $AssemblyKeysByResourceKey; ResourceKeysByAssemblyKey = $ResourceKeysByAssemblyKey; ResourceKeysByAssembly = $ResourceKeysByAssembly}
	$State.PatchedAssemblyResourceKeys = [Collections.Generic.HashSet[s3pi.Interfaces.TGIBlock]]::new(8)
	$State.WinProcLayoutsByControlIDChainLength = $WinProcLayoutsByControlIDChainLength

	$HandlePatchedAssemblies = `
	{
		Param ($AssemblyPatchRegistrations, $SourcePatchset)

		if ($Null -ne $AssemblyPatchRegistrations.PatchedAssemblies)
		{
			$State.PatchedAssemblyResourceKeys.UnionWith(
				[s3pi.Interfaces.TGIBlock[]] $(
					foreach ($Registration in $AssemblyPatchRegistrations.PatchedAssemblies)
					{
						$ResourceKey = [s3pi.Interfaces.TGIBlock]::new(1, $Null, $Registration.ResourceKey)
						$AssemblyName = "$($State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$ResourceKey]).Name.Name).dll"

						[TinyUIFixPSForTS3]::WriteLineQuickly("The `"$AssemblyName`" assembly, with a resource-key of $ResourceKey, was patched by the `"$($SourcePatchset.Definition.ID)`" patchset.")

						$ResourceKey
					}
				)
			)
		}
	}

	foreach ($Patchset in $Patchsets)
	{
		if ($Null -ne $Patchset.Instance.DuringUIScaling)
		{
			if ($Patchset.Instance.DuringUIScaling.PatchAssemblies -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Applying the DuringUIScaling assembly patches from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $HandlePatchedAssemblies (& $Patchset.Instance.DuringUIScaling.PatchAssemblies -Self $Patchset.Instance -State $State) $Patchset
			}
		}
	}

	foreach ($Patchset in $PatchsetsRetro)
	{
		if ($Null -ne $Patchset.Instance.DuringUIScaling)
		{
			if ($Patchset.Instance.DuringUIScaling.PatchAssembliesRetro -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Applying the DuringUIScaling assembly retro-patches from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $HandlePatchedAssemblies (& $Patchset.Instance.DuringUIScaling.PatchAssembliesRetro -Self $Patchset.Instance -State $State) $Patchset
			}
		}
	}


	foreach ($ResourceKey in $State.PatchedAssemblyResourceKeys.GetEnumerator())
	{
		$PatchedAssembly = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$ResourceKey])
		$AssemblyStream = $AssemblyStreams[$ResourceKey]

		$PatchedResource = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::S3SATypeID)
		$PatchedAssembly.Write()
		$AssemblyStream.Position = 0

		$PatchedResource.Assembly = [IO.BinaryReader]::new($AssemblyStream)
		$IndexEntry = $State.IntoPackage.AddResource($ResourceKey, $PatchedResource.Stream, $False)
		$IndexEntry.Compressed = if ($Uncompressed) {0} else {0xffff}
	}

	if ($Null -ne $OutputUnpackedAssemblyDirectoryPath)
	{
		$OutputUnpackedAssemblyDirectory = New-Item -ItemType Directory -Force -Path $OutputUnpackedAssemblyDirectoryPath
	}

	if ($Null -ne $OutputUnpackedAssemblyDirectory)
	{
		foreach ($AssemblyStream in $AssemblyStreams.GetEnumerator())
		{
			$AssemblyStream.Value.Position = 0
			$AssemblyName = "$($State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$AssemblyStream.Key]).Name.Name).dll"
			$AssemblyDestination = Join-Path $OutputUnpackedAssemblyDirectory.FullName $AssemblyName

			[TinyUIFixPSForTS3]::WriteLineQuickly("Writing `"$AssemblyName`" to `"$AssemblyDestination`".")

			[TinyUIFixPSForTS3]::UseDisposable(
				{[IO.File]::OpenWrite($AssemblyDestination)},
				{Param ($File) $AssemblyStream.Value.CopyTo($File)}
			)
		}
	}


	foreach ($Patchset in $Patchsets)
	{
		if ($Null -ne $Patchset.Instance.AfterUIScaling)
		{
			if ($Patchset.Instance.AfterUIScaling.ApplyPatch -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Applying the AfterUIScaling patch from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $Patchset.Instance.AfterUIScaling.ApplyPatch -Self $Patchset.Instance -State $State > $Null
			}
		}
	}

	foreach ($Patchset in $PatchsetsRetro)
	{
		if ($Null -ne $Patchset.Instance.AfterUIScaling)
		{
			if ($Patchset.Instance.AfterUIScaling.ApplyPatchRetro -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Applying the AfterUIScaling retro-patch from the `"$($Patchset.Definition.ID)`" patchset.")

				$State.Logger.CurrentPatchset = $Patchset
				& $Patchset.Instance.AfterUIScaling.ApplyPatchRetro -Self $Patchset.Instance -State $State > $Null
			}
		}
	}
}


function Split-ParametersString ([String] $Value)
{
	$Index = 0
	$Start = 0
	$Length = 0
	$GenericDepth = 0

	foreach ($CodeUnit in $Value.GetEnumerator())
	{
		++$Length

		if ($CodeUnit -ceq [Char] ',')
		{
			if ($GenericDepth -eq 0)
			{
				$Value.SubString($Start, $Length - 1)
				$Start = $Index + 1
				$Length = 0
			}
		}
		elseif ($CodeUnit -ceq [Char] '<')
		{
			++$GenericDepth
		}
		elseif ($CodeUnit -ceq [Char] '>')
		{
			--$GenericDepth
		}

		++$Index
	}

	if ($Length -gt 0)
	{
		$Value.SubString($Start, $Length)
	}
}


function Find-MethodByFullyQualifiedName ([Mono.Cecil.ModuleDefinition] $InModule, [String] $Name)
{
	$ReturnType, $FullName = [RegEx]::new('\s+').Split([String[]] $Name.Trim(), 2, [StringSplitOptions]::None)
	$TypeFullName, $NameAndParameters = $FullName.Split([String[]] '::', 2, [StringSplitOptions]::None)
	$LeftBracketIndex = $NameAndParameters.IndexOf([Char] '(')
	$Name = $NameAndParameters.SubString(0, $LeftBracketIndex)
	$ParameterStrings = Split-ParametersString ($NameAndParameters.SubString($LeftBracketIndex + 1, $NameAndParameters.LastIndexOf([Char] ')') - $LeftBracketIndex - 1))

	$Type = $InModule.GetType($TypeFullName)

	$Method = $Type.Methods.Where(
		{
			     $_.Parameters.Count -eq $ParameterStrings.Count `
			-and $_.Name -ceq $Name `
			-and $_.ReturnType.FullName -ceq $ReturnType `
			-and ($_.Parameters.Count -eq 0 -or [Linq.Enumerable]::SequenceEqual([String[]] $_.Parameters.ParameterType.FullName, [String[]] $ParameterStrings))
		},
		'First'
	)[0]

	if ($Null -eq $Method)
	{
		if ($ParameterStrings.Count -eq 1)
		{
			if ($Name.StartsWith('set_'))
			{
				$Method = $Type.Properties.Where(
					{
						     $Null -ne $_.SetMethod `
						-and $_.SetMethod.Parameters.Count -eq 1 `
						-and $_.SetMethod.Name -ceq $Name `
						-and $_.SetMethod.ReturnType.FullName -ceq $ReturnType `
						-and $_.SetMethod.Parameters[0].ParameterType.FullName -ceq $ParameterStrings[0]
					},
					'First'
				)[0]
			}
		}
		elseif ($ParameterStrings.Count -eq 0)
		{
			if ($Name.StartsWith('get_'))
			{
				$Method = $Type.Properties.Where(
					{
						     $Null -ne $_.GetMethod `
						-and $_.GetMethod.Parameters.Count -eq 0 `
						-and $_.GetMethod.Name -ceq $Name `
						-and $_.GetMethod.ReturnType.FullName -ceq $ReturnType
					},
					'First'
				)[0]
			}
		}
	}

	$Method
}


function Group-FieldsByPath ([String[]] $Paths)
{
	$Tree = [Ordered] @{}

	foreach ($Path in $Paths)
	{
		$ParentNode = $Tree
		$Names = $Path.Split([Char] '.')

		foreach ($Name in $Names)
		{
			$Node = $ParentNode[$Name]
			if ($Null -eq $Node) {$ParentNode[$Name] = ($Node = [Ordered] @{})}
			$ParentNode = $Node
		}
	}

	$Tree
}


function Find-InstanceFieldsForGroupedFieldPaths ([Mono.Cecil.TypeDefinition] $InType, $GroupedPaths)
{
	$Tree = @{Children = [Ordered] @{}}
	$Type = $InType

	$Find = `
	{
		Param ($Type, $PathLevel, $Fields)

		foreach ($Field in $Type.Fields)
		{
			if (-not $Field.IsStatic)
			{
				$Paths = $PathLevel[$Field.Name]

				if ($Null -ne $Paths)
				{
					$ResolvedField = $Field.Resolve()

					$Fields.Children[$Field.FullName] = ($Node = @{ResolvedField = $ResolvedField; Children = [Ordered] @{}})

					foreach ($Path in $Paths)
					{
						& $Find $ResolvedField.FieldType.Resolve() $Paths $Node
					}
				}
			}
		}
	}

	& $Find $InType $GroupedPaths $Tree

	$Tree
}


function Apply-ConvenientPatchesToAssemblies ($Patches, [TinyUIFixForTS3Patcher.AssemblyScaling+PrimitiveAssemblyResolver] $AssemblyResolver, $AssemblyKeysByResourceKey)
{
	$FloatOccurrenceCounts = [Collections.Generic.Dictionary[Float, UInt32]]::new()
	$IntegerOccurrenceCounts = [Collections.Generic.Dictionary[Int32, UInt32]]::new()
	$ArraysBeingScaled = [Collections.Generic.List[ValueTuple[Mono.Cecil.FieldDefinition, Int32, Bool]]]::new()
	$StaticFieldTypeLookup = [Collections.Generic.Dictionary[String, Mono.Cecil.TypeReference]]::new()
	$StaticFieldPathsByField = [Collections.Generic.Dictionary[Mono.Cecil.FieldDefinition, Collections.Generic.List[ValueTuple[String, Object]]]]::new()
	$StaticFieldTreesByField = [Collections.Generic.Dictionary[Mono.Cecil.FieldDefinition, Object]]::new()
	$LocalOfTypeCache = [Collections.Generic.Dictionary[Mono.Cecil.TypeReference, Mono.Cecil.Cil.VariableDefinition]]::new()
	$StaticFieldHexResourceKeyRegEx = [RegEx]::new("^:$([TinyUIFixPSForTS3]::HexResourceKeyRegExPattern)/(?<TypeFullName>.*)", [Text.RegularExpressions.RegexOptions]::Compiled)

	foreach ($PatchesByAssembly in $Patches.GetEnumerator())
	{
		if ($Null -eq $PatchesByAssembly.Value.TinyUIFixForTS3IntegrationTypeNamespace -and $PatchesByAssembly.Value.Patches.Count -eq 0)
		{
			continue
		}

		$Assembly = $AssemblyResolver.Resolve($AssemblyKeysByResourceKey[$PatchesByAssembly.Key])
		$Module = $Assembly.MainModule

		$TinyUIFixForTS3IntegrationType = $Module.GetType("$($PatchesByAssembly.Value.TinyUIFixForTS3IntegrationTypeNamespace).TinyUIFixForTS3Integration")

		if ($Null -eq $TinyUIFixForTS3IntegrationType)
		{
			$TinyUIFixForTS3IntegrationType = New-TinyUIFixForTS3IntegrationType -Namespace $PatchesByAssembly.Value.TinyUIFixForTS3IntegrationTypeNamespace -ForModule $Module
			$Module.Types.Add($TinyUIFixForTS3IntegrationType)
		}

		$GetUIScale = Find-StaticField $TinyUIFixForTS3IntegrationType getUIScale
		$GetUIScaleType = $GetUIScale.FieldType.Resolve()
		$GetUIScaleInvoke = Find-InstanceMethod $GetUIScaleType Invoke

		$ScaleFloatOnStack = `
		{
			[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldsfld, $GetUIScale)
			[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $GetUIScaleInvoke)
			[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul)
		}

		$TruncateFloatOnStack = `
		{
			[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_I4)
			[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_R4)
		}

		$ScaleIntOnStack = `
		{
			Param ([Mono.Cecil.Cil.OpCode[]] $ToInt, [Switch] $Unsigned)

			if ($Unsigned) {[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_R_Un)}
			[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_R4)

			& $ScaleFloatOnStack

			$ToInt.ForEach{[Mono.Cecil.Cil.Instruction]::Create($_)}
		}

		foreach ($Patch in $PatchesByAssembly.Value.Patches)
		{
			$Method = Find-MethodByFullyQualifiedName $Module $Patch[0]

			if ($Null -eq $Method)
			{
				if (-not $Patch[1].Optional)
				{
					Write-Warning "Could not find the method specified by: $($Patch[0])"
				}

				continue
			}

			$FloatOccurrenceCounts.Clear()
			$IntegerOccurrenceCounts.Clear()
			$ArraysBeingScaled.Clear()
			$LocalOfTypeCache.Clear()
			$StaticFieldPathsByField.Clear()
			$StaticFieldTreesByField.Clear()
			$InstanceFieldTree = $Null
			$StaticFieldTree = $Null
			$Integers = $Null

			Edit-MethodBody $Method `
			{
				$Instruction = $IL.Body.Instructions[0]

				:ForEachInstruction while ($Null -ne $Instruction)
				{
					if (
						    $Instruction.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Cond_Branch `
						-or $Instruction.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Return `
						-or $Instruction.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Throw
					)
					{
						if ($ArraysBeingScaled.Count -gt 0)
						{
							Write-Warning "Conditional control-flow was encountered while patching ""$Method"", and thus the following arrays could not be scaled: $(($ArraysBeingScaled.Item1.FullName | Select-Object -Unique | % {"$('"')$_$('"')"}) -join '; ')."

							$ArraysBeingScaled.Clear()
						}
					}
					else
					{
						$StackDepthDelta = 0

						if (-not [TinyUIFixForTS3Patcher.AssemblyScaling+OpCodeInspection]::StaticallyKnownStackDepthChangeEffectedBy($Instruction, [Ref] $StackDepthDelta))
						{
							if ($ArraysBeingScaled.Count -gt 0)
							{
								Write-Warning "A non-statically known stack depth change was encountered while patching ""$Method"", and thus the following arrays could not be scaled: $(($ArraysBeingScaled.Item1.FullName | Select-Object -Unique | % {"$('"')$_$('"')"}) -join '; ')."

								$ArraysBeingScaled.Clear()
							}
						}

						for ($Index = 0; $Index -lt $ArraysBeingScaled.Count; ++$Index)
						{
							$ArraysBeingScaled[$Index].Item2 += $StackDepthDelta
						}

						for ($Index = $ArraysBeingScaled.Count; ($Index--) -gt 0;)
						{
							if ($ArraysBeingScaled[$Index].Item2 -lt 0)
							{
								$ArraysBeingScaled.RemoveAt($Index)
							}
						}

						if ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Dup)
						{
							if ($ArraysBeingScaled.Count -gt 0)
							{
								$LastArray = $ArraysBeingScaled[$ArraysBeingScaled.Count - 1]

								if ($LastArray.Item2 -eq 1)
								{
									$ArraysBeingScaled.Add([ValueTuple[Mono.Cecil.FieldDefinition, Int32, Bool]]::new($LastArray.Item1, 0, $LastArray.Item3))
								}
							}
						}
						elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldc_R4)
						{
							foreach ($Value in $Patch[1].Floats)
							{
								$IsSimpleScalar = $Value -as [Float]
								$Scalar = $IsSimpleScalar

								$ShouldTruncate = if ($IsSimpleScalar)
								{
									$False
								}
								else
								{
									$Scalar = $Value._ -as [Float]
									$Value.Truncated
								}

								$ShouldScaleBasedOnScalar = if ($Null -ne $Scalar)
								{
									$OccurrenceCount = $Null
									$FloatOccurrenceCounts[$Scalar] = if ($FloatOccurrenceCounts.TryGetValue($Scalar, [Ref] $OccurrenceCount)) {(++$OccurrenceCount)} else {($OccurrenceCount = 0)}

									$Instruction.Operand -eq $Scalar
								}
								else
								{
									-not $IsSimpleScalar
								}

								$ShouldScale = if (-not $IsSimpleScalar -and $Null -ne $Value.'?')
								{
									     $ShouldScaleBasedOnScalar `
									-and $(
										$Accepting = $Value.'?'.Ast.ParamBlock.Parameters.Name.VariablePath.UserPath
										$Supplying = @{}

										if ($Accepting.Contains('OccurrenceIndex')) {$Supplying.OccurrenceIndex = $OccurrenceCount}
										if ($Accepting.Contains('Instruction')) {$Supplying.Instruction = $Instruction}

										& $Value.'?' @Supplying
									)
								}
								else
								{
									$ShouldScaleBasedOnScalar
								}

								if ($ShouldScale)
								{
									$AfterLoad = $Instruction.Next

									(& $ScaleFloatOnStack).ForEach{$IL.InsertBefore($AfterLoad, $_)}

									if ($ShouldTruncate)
									{
										(& $TruncateFloatOnStack).ForEach{$IL.InsertBefore($AfterLoad, $_)}
									}

									$Instruction = $AfterLoad

									continue ForEachInstruction
								}
							}
						}
						elseif (
							$(
								if ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldsfld -or $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldsflda)
								{
									if ($Patch[1].StaticFields)
									{
										$LoadedField = $Instruction.Operand.Resolve()
										$IsStatic = $True
										$IsReference = $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldsflda
										$True
									}
								}
								elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldfld -or $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldflda)
								{
									if ($Patch[1].InstanceFields)
									{
										$LoadedField = $Instruction.Operand.Resolve()
										$IsStatic = $False
										$IsReference = $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldflda
										$True
									}
								}
								elseif (
									$(
										if ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_Any -and $ArraysBeingScaled.Count -gt 0)
										{
											$LastArray = $ArraysBeingScaled[$ArraysBeingScaled.Count - 1]
											$LastArray.Item2 -eq 0
										}
									)
								)
								{
									$ArraysBeingScaled.RemoveAt($ArraysBeingScaled.Count - 1)
									$LoadedField = $LastArray.Item1
									$IsStatic = $LastArray.Item3
									$IsReference = $False
									$True
								}
							)
						)
						{
							$LoadedFieldType = if ($LoadedField.FieldType.MetadataToken.TokenType -eq [Mono.Cecil.TokenType]::TypeSpec) {$LoadedField.FieldType} else {$LoadedField.FieldType.Resolve()}

							if ($IsStatic)
							{
								if ($StaticFieldPathsByField.Count -eq 0)
								{
									$Patch[1].StaticFields.ForEach{
										$Specifier = if ($_ -is [String]) {$_} else {$_._}
										$NameOrType, $Name = $Specifier.Split([String[]] '::', 2, [StringSplitOptions]::None)

										$Type = $Null

										$Path = if ($Null -eq $Name)
										{
											$Type = $Method.DeclaringType.Resolve()

											$NameOrType
										}
										else
										{
											if (-not $StaticFieldTypeLookup.TryGetValue($NameOrType, [Ref] $Type))
											{
												$ResourceKeyPrefixMatch = $StaticFieldHexResourceKeyRegEx.Match($NameOrType)

												$Type = if ($ResourceKeyPrefixMatch.Success)
												{
													$ResourceKey = [s3pi.Interfaces.TGIBlock]::new(
														1,
														$Null,
														[Convert]::ToUInt32($ResourceKeyPrefixMatch.Groups[1].Value, 16),
														[Convert]::ToUInt32($ResourceKeyPrefixMatch.Groups[2].Value, 16),
														[Convert]::ToUInt64($ResourceKeyPrefixMatch.Groups[3].Value, 16)
													)

													$AssemblyKey = $AssemblyKeysByResourceKey[$ResourceKey]

													if ($Null -ne $AssemblyKey)
													{
														$AssemblyResolver.Resolve($AssemblyKey).MainModule.GetType($ResourceKeyPrefixMatch.Groups[4].Value)
													}
													else
													{
														Write-Warning "No assembly could be found for the resource-key $NameOrType."
													}
												}
												else
												{
													$Module.GetType($NameOrType)
												}

												$StaticFieldTypeLookup[$NameOrType] = $Type
											}

											$Name
										}

										if ($Null -eq $Type)
										{
											Write-Warning "The type $NameOrType could not be found."
										}
										else
										{
											$RootFieldPath, $FieldPaths = $Path.Split([Char] '.', 2)
											$RootField = $Type.Fields.Where({$_.IsStatic -and $_.Name -ceq $RootFieldPath}, 'First')[0]

											if ($Null -eq $RootField)
											{
												Write-Warning "No static-field named `"$RootFieldPath`" could be found for the type $Type."
											}
											else
											{
												$PathsForStaticField = $Null
												if (-not $StaticFieldPathsByField.TryGetValue($RootField, [Ref] $PathsForStaticField))
												{
													$PathsForStaticField = [Collections.Generic.List[ValueTuple[String, Object]]]::new()
													$StaticFieldPathsByField[$RootField] = $PathsForStaticField
												}

												$PathsForStaticField.Add([ValueTuple[String, Object]]::new($FieldPaths, $(if ($_ -is [String]) {$Null} else {$_})))
											}
										}
									}
								}

								$StaticFieldTree = $Null
								if (-not $StaticFieldTreesByField.TryGetValue($LoadedField, [Ref] $StaticFieldTree))
								{
									$StaticFieldPaths = $Null
									if ($StaticFieldPathsByField.TryGetValue($LoadedField, [Ref] $StaticFieldPaths))
									{
										$StaticFieldTree = Find-InstanceFieldsForGroupedFieldPaths $(if ($LoadedFieldType -is [Mono.Cecil.TypeDefinition]) {$LoadedFieldType} else {$LoadedFieldType.Resolve()}) (Group-FieldsByPath $StaticFieldPaths.Item1)
										$StaticFieldTreesByField[$LoadedField] = $StaticFieldTree
									}
								}

								$Scaling = $StaticFieldTree
							}
							else
							{
								if ($Null -eq $InstanceFieldTree)
								{
									$InstanceFieldTree = Find-InstanceFieldsForGroupedFieldPaths $Method.DeclaringType.Resolve() (Group-FieldsByPath $Patch[1].InstanceFields)
								}

								$Scaling = $InstanceFieldTree.Children[$LoadedField.FullName]
							}


							$AfterLoad = $Instruction.Next

							if ($Null -ne $Scaling)
							{
								if ($LoadedFieldType.IsArray)
								{
									if (-not $IsReference)
									{
										$ArraysBeingScaled.Add([ValueTuple[Mono.Cecil.FieldDefinition, Int32, Bool]]::new($LoadedField, 0, $IsStatic))
									}
								}
								else
								{
									$ScaleByValueField = `
									{
										Param ([Mono.Cecil.TypeReference] $TypeOfValue, $FieldTreeToScale, [Mono.Cecil.Cil.Instruction] $AfterLoadOfValue)

										if ($FieldTreeToScale.Children.Count -eq 0)
										{
											if ($TypeOfValue.Namespace -ceq 'System')
											{
												if ($TypeOfValue.Name -ceq 'Single')
												{
													(& $ScaleFloatOnStack).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
												elseif ($TypeOfValue.Name -ceq 'Int32')
												{
													(& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I4)).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
												elseif ($TypeOfValue.Name -ceq 'UInt32')
												{
													(& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U4)).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
												elseif ($TypeOfValue.Name -ceq 'Int16')
												{
													(& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I2)).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
												elseif ($TypeOfValue.Name -ceq 'UInt16')
												{
													(& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U2)).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
												elseif ($TypeOfValue.Name -ceq 'SByte')
												{
													(& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I1)).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
												elseif ($TypeOfValue.Name -ceq 'Byte')
												{
													(& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U1)).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}
												}
											}
										}
										else
										{
											$Local = $Null
											if (-not $LocalOfTypeCache.TryGetValue($TypeOfValue, [Ref] $Local))
											{
												$Local = Add-VariableToMethod $Method $(if ($TypeOfValue.Module -eq $Module) {$TypeOfValue} else {$Module.Import($TypeOfValue)})
												$LocalOfTypeCache[$TypeOfValue] = $Local
											}

											$IL.InsertBefore($AfterLoadOfValue, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $Local))
											$IL.InsertBefore($AfterLoadOfValue, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloca, $Local))

											for ($Index = 1; $Index -lt $FieldTreeToScale.Children.Count; ++$Index)
											{
												$IL.InsertBefore($AfterLoadOfValue, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
											}

											$NestedScale = `
											{
												Param ($FieldNode)

												foreach ($Field in $FieldNode.Children.Values)
												{
													$ResolvedField = $Field.ResolvedField
													$Children = $Field.Children

													[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldflda, $(if ($ResolvedField.Module -eq $Module) {$ResolvedField} else {$Module.Import($ResolvedField)}))

													if ($Children.Count -eq 0)
													{
														if ($ResolvedField.FieldType.Namespace -ceq 'System')
														{
															if ($ResolvedField.FieldType.Name -ceq 'Single')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_R4)
																& $ScaleFloatOnStack
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_R4)
															}
															elseif ($ResolvedField.FieldType.Name -ceq 'Int32')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_I4)
																& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I4)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_I4)
															}
															elseif ($ResolvedField.FieldType.Name -ceq 'UInt32')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_U4)
																& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U4)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_U4)
															}
															elseif ($ResolvedField.FieldType.Name -ceq 'Int16')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_I2)
																& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I2)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_I2)
															}
															elseif ($ResolvedField.FieldType.Name -ceq 'UInt16')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_U2)
																& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U2)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_U2)
															}
															elseif ($ResolvedField.FieldType.Name -ceq 'SByte')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_I1)
																& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I1)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_I1)
															}
															elseif ($ResolvedField.FieldType.Name -ceq 'Byte')
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldind_U1)
																& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U1)
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stind_U1)
															}
															else
															{
																[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Pop)
															}
														}
														else
														{
															[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Pop)
														}
													}
													else
													{
														for ($Index = 1; $Index -lt $Children.Count; ++$Index)
														{
															[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)
														}

														& $NestedScale $Field
													}
												}
											}

											(& $NestedScale $FieldTreeToScale).ForEach{$IL.InsertBefore($AfterLoadOfValue, $_)}

											$IL.InsertBefore($AfterLoadOfValue, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $Local))
										}
									}

									if ($IsReference)
									{
										$ScaleFromReferenceToField = `
										{
											Param ([Mono.Cecil.TypeReference] $TypeOfReference, $FieldTreeToScale, [Mono.Cecil.Cil.Instruction] $FromInstruction)

											$StackDepth = 0
											$NextInstruction = $FromInstruction

											while ($NextInstruction = $NextInstruction.Next)
											{
												$StackDepthDelta = 0

												if (-not [TinyUIFixForTS3Patcher.AssemblyScaling+OpCodeInspection]::StaticallyKnownStackDepthChangeEffectedBy($NextInstruction, [Ref] $StackDepthDelta))
												{
													Write-Warning "A non-statically known stack depth change was encountered while patching ""$Method"", and thus some fields won't be scaled."

													return
												}

												$StackDepth += $StackDepthDelta

												if ($StackDepth -eq 1)
												{
													if ($NextInstruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Dup)
													{
														$NextInstruction = & $ScaleFromReferenceToField $TypeOfReference $FieldTreeToScale $FromInstruction
													}
												}
												elseif ($StackDepth -eq 0)
												{
													if ($NextInstruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldflda)
													{
														$FieldNode = $FieldTreeToScale.Children[$NextInstruction.Operand.FullName]

														if ($Null -ne $FieldNode)
														{
															& $ScaleFromReferenceToField $NextInstruction.Operand.FieldType $FieldNode $NextInstruction > $Null
														}

														return $NextInstruction
													}
													elseif ($NextInstruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldfld)
													{
														$FieldNode = $FieldTreeToScale.Children[$NextInstruction.Operand.FullName]

														if ($Null -ne $FieldNode)
														{
															& $ScaleByValueField $NextInstruction.Operand.FieldType $FieldNode $NextInstruction.Next
														}

														return $NextInstruction
													}
												}
												elseif ($StackDepth -lt 0)
												{
													return
												}
											}
										}

										if ($Scaling.Children.Count -gt 0)
										{
											& $ScaleFromReferenceToField $LoadedFieldType $Scaling $Instruction > $Null
										}
									}
									else
									{
										& $ScaleByValueField $LoadedFieldType $Scaling $AfterLoad
									}
								}
							}

							$Instruction = $AfterLoad

							continue ForEachInstruction

						}
	 					elseif (
							$(
								if ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldc_I4  -or $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldc_I4_S)
								{
									$IsCompact = $False
									$True
								}
								elseif ($CompactLdcI4Codes.Contains($Instruction.OpCode.Code))
								{
									$IsCompact = $True
									$True
								}
								else
								{
									$False
								}
							)
						)
						{
							foreach ($Value in $Patch[1].Integers)
							{
								$IsSimpleScalar = if ($Value -is [UInt32]) {$Value} else {$Value -as [Int32]}
								$Scalar = $IsSimpleScalar

								if (-not $IsSimpleScalar)
								{
									$Scalar = $Value._
									$Scalar = if ($Scalar -is [UInt32]) {$Scalar} else {$Scalar -as [Int32]}
								}

								$IsUnsigned = $Scalar -is [UInt32]
								$OperandValue = if ($IsUnsigned) {[TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($Scalar)} else {$Scalar}

								$ShouldScaleBasedOnScalar = if ($Null -ne $OperandValue)
								{
									$OccurrenceCount = $Null
									$IntegerOccurrenceCounts[$OperandValue] = if ($IntegerOccurrenceCounts.TryGetValue($OperandValue, [Ref] $OccurrenceCount)) {(++$OccurrenceCount)} else {($OccurrenceCount = 0)}

									if ($IsCompact)
									{
										$OperandValue -ge -1 -and $OperandValue -le 8 -and $Instruction.OpCode.Code -eq $CompactLdcI4Codes[$OperandValue + 1]
									}
									else
									{
										$Instruction.Operand -eq $OperandValue
									}
								}
								else
								{
									-not $IsSimpleScalar
								}

								$ShouldScale = if (-not $IsSimpleScalar -and $Null -ne $Value.'?')
								{
									     $ShouldScaleBasedOnScalar `
									-and $(
										$Accepting = $Value.'?'.Ast.ParamBlock.Parameters.Name.VariablePath.UserPath
										$Supplying = @{}

										if ($Accepting.Contains('OccurrenceIndex')) {$Supplying.OccurrenceIndex = $OccurrenceCount}
										if ($Accepting.Contains('Instruction')) {$Supplying.Instruction = $Instruction}

										& $Value.'?' @Supplying
									)
								}
								else
								{
									$ShouldScaleBasedOnScalar
								}

								if ($ShouldScale)
								{
									$AfterLoad = $Instruction.Next

									(& $ScaleIntOnStack $(if ($IsUnsigned) {[Mono.Cecil.Cil.OpCodes]::Conv_U4} ;[Mono.Cecil.Cil.OpCodes]::Conv_I4) -Unsigned:$IsUnsigned).ForEach{$IL.InsertBefore($AfterLoad, $_)}

									$Instruction = $AfterLoad

									continue ForEachInstruction
								}
							}
						}
						else
						{

							$ScaleArrayUsing = `
							{
								Param ($Scale)

								if ($ArraysBeingScaled.Count -gt 0 -and $ArraysBeingScaled[$ArraysBeingScaled.Count - 1].Item2 -eq 0)
								{
									$ArraysBeingScaled.RemoveAt($ArraysBeingScaled.Count - 1)

									$AfterLoad = $Instruction.Next

									(& $Scale).ForEach{$IL.InsertBefore($AfterLoad, $_)}
								}
							}

							if ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_R4)
							{
								& $ScaleArrayUsing $ScaleFloatOnStack
							}
							elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_I4)
							{
								& $ScaleArrayUsing {& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I4)}
							}
							elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_U4)
							{
								& $ScaleArrayUsing {& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U4)}
							}
							elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_I2)
							{
								& $ScaleArrayUsing {& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I2)}
							}
							elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_U2)
							{
								& $ScaleArrayUsing {& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U2)}
							}
							elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_I1)
							{
								& $ScaleArrayUsing {& $ScaleIntOnStack ([Mono.Cecil.Cil.OpCodes]::Conv_I1)}
							}
							elseif ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldelem_U1)
							{
								& $ScaleArrayUsing {& $ScaleIntOnStack -Unsigned ([Mono.Cecil.Cil.OpCodes]::Conv_U1)}
							}
						}
					}

					$Instruction = $Instruction.Next
				}
			} > $Null
		}

		@{ResourceKey = $PatchesByAssembly.Key; Assembly = $Assembly}
	}
}


function Read-AvailablePatchsets ($From = (Join-Path $PSScriptRoot Patchsets), $MinimumSchemaVersion = 1, $MaximumSchemaVersion = 1)
{
	$PatchsetsPath = $From
	$PatchsetsByID = [Collections.Generic.Dictionary[String, TinyUIFixForTS3PatchsetDefinition]]::new()
	$PatchsetsWithConflictingIDs = [Collections.Generic.Dictionary[String, Collections.Generic.List[TinyUIFixForTS3PatchsetDefinition]]]::new(0)
	$InvalidPowerShellScripts = [Collections.Generic.List[ValueTuple[String, Exception]]]::new(0)
	$InvalidPatchsets = [Collections.Generic.List[ValueTuple[String, String]]]::new(0)
	$ProcessedCount = 0

	$ReadFileNames = [Collections.Generic.List[String]]::new()
	$StreamReaders = [Collections.Generic.List[IO.StreamReader]]::new()
	$ReadFileTasks = [Threading.Tasks.Task[]] $(
		foreach ($File in ([IO.DirectoryInfo] $PatchsetsPath).EnumerateFiles('*.ps1'))
		{
			$ReadFileNames.Add($File.FullName)

			$StreamReader = [IO.StreamReader]::new(
				[IO.FileStream]::new($File.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete, 4096, $True),
				$True
			)
			$StreamReaders.Add($StreamReader)

			$StreamReader.ReadToEndAsync()
		}
	)

	$NeverCompletes = [Threading.Tasks.Task]::Delay(-1)

	for ($ProcessedCount = 0; $ProcessedCount -lt $ReadFileTasks.Count; ++$ProcessedCount)
	{
		$TaskIndex = [Threading.Tasks.Task]::WaitAny($ReadFileTasks)
		$StreamReaders[$TaskIndex].Dispose()
		$ReadFileTask = $ReadFileTasks[$TaskIndex]
		$ReadFileTasks[$TaskIndex] = $NeverCompletes
		$FileFullName = $ReadFileNames[$TaskIndex]

		try
		{
			$ScriptBlock = [ScriptBlock]::Create($ReadFileTask.Result)
		}
		catch
		{
			$InvalidPowerShellScripts.Add([ValueTuple[String, Exception]]::new($FileFullName, $_.Exception))
			continue
		}

		$Block = $ScriptBlock.Ast.BeginBlock
		if ($Null -eq $Block) {$Block = $ScriptBlock.Ast.ProcessBlock}
		if ($Null -eq $Block) {$Block = $ScriptBlock.Ast.EndBlock}

		$Statements = $Block.Statements[0 .. 2]

		if ($Null -ne $Statements.Where({-not ($_ -is [Management.Automation.Language.AssignmentStatementAst])}, 'First')[0])
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, 'It does not begin with a declaration of its ID, its version, and its targeted schema version.'))
			continue
		}

		$Declarations = @{}

		foreach ($Statement in $Statements)
		{
			if ($Statement.Operator -ne [Management.Automation.Language.TokenKind]::Equals)
			{
				$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} does not use the equals operator for assignment."))
				continue
			}

			if (-not ($Statement.Left -is [Management.Automation.Language.VariableExpressionAst]))
			{
				$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} does not assign to a variable."))
				continue
			}

			if ($Statement.Left.Splatted -or -not $Statement.Left.VariablePath.IsVariable -or -not $Statement.Left.VariablePath.IsUnscopedVariable -or -not $Statement.Left.VariablePath.IsUnqualified)
			{
				$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} does not assign to an unscoped and unqualified variable."))
				continue
			}

			$Key = $Statement.Left.VariablePath.UserPath

			if ($Null -ne $Declarations[$Key])
			{
				$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} assigns a declaration that was already assigned."))
				continue
			}

			if (-not ($Statement.Right -is [Management.Automation.Language.CommandExpressionAst]))
			{
				$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} does not assign an signed 32-bit integer or singled-quoted string literal."))
				continue
			}
			elseif ($Statement.Right.Expression -is [Management.Automation.Language.StringConstantExpressionAst])
			{
				if ($Statement.Right.Expression.StringConstantType -ne [Management.Automation.Language.StringConstantType]::SingleQuoted)
				{
					$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} does not assign a singled-quoted string literal."))
					continue
				}

				$Declarations[$Key] = $Statement.Right.Expression.Value
			}
			elseif ($Statement.Right.Expression -is [Management.Automation.Language.ConstantExpressionAst] -and -not ($Statement.Right.Expression.StaticType -is [Int32]))
			{
				$Declarations[$Key] = $Statement.Right.Expression.Value
			}
			else
			{
				$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "{$($Statement.Extent.Text)} does not assign a signed 32-bit integer or singled-quoted string literal."))
				continue
			}
		}

		if ($Null -eq $Declarations.ID -or -not ($Declarations.ID -is [String]))
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "It does not declare an ID as a string."))
			continue
		}

		if (-not [TinyUIFixForTS3PatchsetDefinition]::ValidIDRegEx.IsMatch($Declarations.ID))
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "Its declared ID of `"$($Declaration.ID)`" is invalid. A patchset's ID can contain only Latin letters, Arabic numerals, and underscores, it must start with a letter, it must be at-least two characters long, and it must not begin with `"TinyUIFix`"."))
			continue
		}

		if ($Null -eq $Declarations.Version -or -not ($Declarations.Version -is [String]))
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "It does not declare a version as a string."))
			continue
		}

		$ParsedVersion = [Version]::new()

		if (-not [Version]::TryParse($Declarations.Version, [Ref] $ParsedVersion))
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "Its declared version is not a version-string recognised by `System.Version::TryParse`."))
			continue
		}

		if ($Null -eq $Declarations.PatchsetDefinitionSchemaVersion -or -not ($Declarations.PatchsetDefinitionSchemaVersion -is [Int32]))
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "It does not declare its targeted PatchsetDefinitionSchemaVersion as a signed 32-bit integer."))
			continue
		}

		if ($Declarations.PatchsetDefinitionSchemaVersion -gt $MaximumSchemaVersion -or $Declarations.PatchsetDefinitionSchemaVersion -lt $MinimumSchemaVersion)
		{
			$InvalidPatchsets.Add([ValueTuple[String, String]]::new($FileFullName, "Its targeted PatchsetDefinitionSchemaVersion is not a known version. The latest version is $MaximumSchemaVersion."))
			continue
		}

		$Patchset = [TinyUIFixForTS3PatchsetDefinition]::new($FileFullName, $Declarations.ID, $ParsedVersion, $Declarations.PatchsetDefinitionSchemaVersion, $ScriptBlock)

		$ConflictingPatchsets = $Null
		$ConflictingPatchset = $Null

		if ($PatchsetsWithConflictingIDs.TryGetValue($Patchset.ID, [Ref] $ConflictingPatchsets))
		{
			$ConflictingPatchsets.Add($Patchset)
		}
		elseif ($PatchsetsByID.TryGetValue($Patchset.ID, [Ref] $ConflictingPatchset))
		{
			$PatchsetsByID.Remove($Patchset.ID) > $Null
			$ConflictingPatchsets = [Collections.Generic.List[TinyUIFixForTS3PatchsetDefinition]]::new(2)
			$ConflictingPatchsets.Add($ConflictingPatchset)
			$ConflictingPatchsets.Add($Patchset)
			$PatchsetsWithConflictingIDs[$Patchset.ID] = $ConflictingPatchsets
		}
		else
		{
			$PatchsetsByID[$Patchset.ID] = $Patchset
		}
	}

	[PSCustomObject] @{PatchsetsByID = $PatchsetsByID; PatchsetsWithConflictingIDs = $PatchsetsWithConflictingIDs; InvalidPowerShellScripts = $InvalidPowerShellScripts; InvalidPatchsets = $InvalidPatchsets}
}


function Import-Patchsets ($PatchsetsByID, $LoadOrder)
{
	$OrderedAndByID = [Ordered] @{}
	$FailedToImport = [Collections.Generic.List[ValueTuple[TinyUIFixForTS3PatchsetDefinition, Exception]]]::new(0)

	foreach ($ID in $LoadOrder.ByIndex)
	{
		$Definition = $PatchsetsByID[$ID]

		try
		{
			[TinyUIFixPSForTS3]::WriteLineQuickly("Loading patchset `"$($Definition.ID)`" from `"$($Definition.FilePath)`".")

			$Instance = & $Definition.ScriptBlock
		}
		catch
		{
			$FailedToImport.Add([ValueTuple[TinyUIFixForTS3PatchsetDefinition, Exception]]::new($Definition, $_.Exception))
			continue
		}

		$OrderedAndByID[$ID] = [TinyUIFixForTS3Patchset]::new($Instance, $Definition)
	}

	@{Patchsets = $OrderedAndByID; FailedToImport = $FailedToImport}
}


function Initialize-Patchsets ($Patchsets, $State)
{
	foreach ($Patchset in $Patchsets.Values)
	{
		if ($Patchset.Instance.InitialiseAfterLoading -is [ScriptBlock])
		{
			[TinyUIFixPSForTS3]::WriteLineQuickly("Initialising the `"$($Patchset.Definition.ID)`" patchset after loading it.")

			$State.Logger.CurrentPatchset = $Patchset
			& $Patchset.Instance.InitialiseAfterLoading -Self $Patchset.Instance -State $State > $Null
		}

		if ($Patchset.Instance.MakeDefaultConfiguration -is [ScriptBlock])
		{
			[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary(
				($State.Configuration[$Patchset.Definition.ID] = [Ordered] @{}),
				$(
					$State.Logger.CurrentPatchset = $Patchset
					& $Patchset.Instance.MakeDefaultConfiguration -Self $Patchset.Instance
				)
			) > $Null
		}
	}
}


function Settle-StateOfPatchsets ($Patchsets, $State)
{
	for (;;)
	{
		$AllSettled = $True

		foreach ($Patchset in $Patchsets.Values)
		{
			if ($Patchset.Instance.SettleStateBeforePatchsetsAreApplied -is [ScriptBlock])
			{
				[TinyUIFixPSForTS3]::WriteLineQuickly("Settling state for the `"$($Patchset.Definition.ID)`" patchset.")

				if (
					$(
						$State.Logger.CurrentPatchset = $Patchset
					    & $Patchset.Instance.SettleStateBeforePatchsetsAreApplied -Self $Patchset.Instance -State $State
					) `
					-eq [TinyUIFixForTS3Patchset]::MoreSettlingOfState
				)
				{
					$AllSettled = $False

					[TinyUIFixPSForTS3]::WriteLineQuickly("The `"$($Patchset.Definition.ID)`" patchset requested that the state be settled once more.")
				}
			}
		}

		if ($AllSettled)
		{
			break
		}
	}
}


function Load-Patchsets ($ReadPatchsets = (Read-AvailablePatchsets), $LoadOrder, $State, $ConfigurationObject)
{
	foreach ($InvalidPowerShellScript in $ReadPatchsets.InvalidPowerShellScripts)
	{
		Write-Warning "The patchset at `"$($InvalidPowerShellScript.Item1)`" could not be loaded as it is not a valid PowerShell script. The error was:$([Environment]::NewLine)$($InvalidPowerShellScript.Item2)"
	}

	foreach ($InvalidPatchset in $ReadPatchsets.InvalidPatchsets)
	{
		Write-Warning "The patchset at `"$($InvalidPatchset.Item1)`" was not loaded because: $($InvalidPatchset.Item2)"
	}

	foreach ($Entry in $ReadPatchsets.PatchsetsWithConflictingIDs.GetEnumerator())
	{
		Write-Warning "There are multiple patchsets with the same ID of `"$($Entry.Key)`", so none of them are being loaded. Those patchsets are: $($Entry.Value.ForEach{'"{0}"' -f $_} -join '; ')."
	}

	$ImportedPatchsets = Import-Patchsets $ReadPatchsets.PatchsetsByID $LoadOrder

	foreach ($FailedImport in $ImportedPatchsets.FailedToImport)
	{
		Write-Error -ErrorAction Continue "An error occurred when loading the patchset at `"$($FailedImport.Item1)`". The error was:$([Environment]::NewLine)$($FailedImport.Item2)"
	}

	$State.PatchsetLoadOrder = $LoadOrder
	$State.Patchsets = $ImportedPatchsets.Patchsets

	Initialize-Patchsets $State.Patchsets $State
	[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary($State.Configuration, $ConfigurationObject) > $Null
	Settle-StateOfPatchsets $State.Patchsets $State

	$ImportedPatchsets
}


function Resolve-PatchsetLoadOrder ([String[]] $LoadOrder, $AvailablePatchsetsByID, [Switch] $LoadOrderNotExplicitlySetByUser)
{
	$ResolvedLoadOrder = [Collections.Generic.List[String]]::new()
	$PositionInLoadOrderByID = [Collections.Generic.Dictionary[String, Int32]]::new()
	$LastIndex = 0

	$ResolvedLoadOrder.Add('Nucleus')
	$PositionInLoadOrderByID['Nucleus'] = ($LastIndex++)

	if ($LoadOrderNotExplicitlySetByUser)
	{
		$ResolvedLoadOrder.Add('VanillaCoreCompatibilityPatch')
		$PositionInLoadOrderByID['VanillaCoreCompatibilityPatch'] = ($LastIndex++)
	}

	foreach ($ID in $LoadOrder)
	{
		if (-not $AvailablePatchsetsByID.ContainsKey($ID) -or $PositionInLoadOrderByID.ContainsKey($ID))
		{
			continue
		}

		$ResolvedLoadOrder.Add($ID)
		$PositionInLoadOrderByID[$ID] = ($LastIndex++)
	}

	[PSCustomObject] @{
		ByIndex = $ResolvedLoadOrder.AsReadOnly()
		ByID = [Collections.ObjectModel.ReadOnlyDictionary[String, Int32]]::new($PositionInLoadOrderByID)
	}
}


function Test-PatchsetIsRecommended ($Patchset, $AllActiveModPackages)
{
	$ModPackageFilePathRegEx = $Patchset.Instance.RecommendUsageInPresenceOfModPackageFilePathsMatching

	if ($ModPackageFilePathRegEx -is [String] -or $ModPackageFilePathRegEx -is [RegEx])
	{
		$MatchedModPackages = $AllActiveModPackages.Where{$_ -match $ModPackageFilePathRegEx}

		[PSCustomObject] @{
			IsRecommended = $MatchedModPackages.Count -gt 0
			MatchedModPackages = $MatchedModPackages
			RecommendationMessage = "$(if ($MatchedModPackages.Count -gt 0) {$Patchset.Instance.RecommendUsageInPresenceOfModPackageFilePathsMessage})"
		}
	}
	else
	{
		[PSCustomObject] @{IsRecommended = $False}
	}
}


function New-PatchingState
{
	@{
		Logger = [TinyUIFixForTS3PatchsetLogger]::new()
		Paths = @{
			Root = $PSScriptRoot
		}
		Configuration = @{}
	}
}


function Test-Sims3Path ($Sims3Path, [Switch] $IsMacOSInstallation)
{
	$Null -ne $Sims3Path -and (Test-Path -LiteralPath (Join-Path $Sims3Path $(if ($IsMacOSInstallation) {'Contents/Resources/Resource.cfg'} else {'Game/Bin/Resource.cfg'})))
}


function Test-Sims3UserDataPath ($Sims3UserDataPath)
{
	$Null -ne $Sims3UserDataPath -and (Test-Path -LiteralPath (Join-Path $Sims3UserDataPath Options.ini))
}


function Resolve-ResourcePrioritiesForSims3InstallationForUIScaling ([String] $Sims3Path, [String] $Sims3UserDataPath, [Switch] $IsMacOSInstallation, [Switch] $IncludeTinyUIFixPackage)
{
	Resolve-ResourcePrioritiesForSims3Installation `
		-Sims3Path $Sims3Path `
		-Sims3UserDataPath $Sims3UserDataPath `
		-IsMacOSInstallation:$IsMacOSInstallation `
		-IncludeTinyUIFixPackage:$IncludeTinyUIFixPackage `
		-TransformGameBinResourceCFG `
		{
			Param ($Lines)

			$Lines
			"Priority $([Int32]::MinValue)"
			'PackedFile gameplay.package'
			'PackedFile scripts.package'
			'PackedFile simcore.package'
		}
}


function New-PackageWithPatchedResources ([PSCustomObject] $UnpatchedResources, $UnpatchedResourcesByPackage, $State, $OutputUnpackedAssemblyDirectoryPath, [Switch] $Uncompressed)
{
	$Package = [s3pi.Package.Package]::NewPackage(1)

	$State.IntoPackage = $Package

	Apply-PatchesToResources $UnpatchedResources $UnpatchedResourcesByPackage $State $OutputUnpackedAssemblyDirectoryPath -Uncompressed:$Uncompressed > $Null
	$Package
}


function Write-PackageWithPatchedResources ([PSCustomObject] $UnpatchedResources, $UnpatchedResourcesByPackage, $State, [String] $FilePath, $OutputUnpackedAssemblyDirectoryPath, [Switch] $Uncompressed)
{
	[TinyUIFixPSForTS3]::UseDisposable(
		{New-PackageWithPatchedResources $UnpatchedResources $UnpatchedResourcesByPackage $State $OutputUnpackedAssemblyDirectoryPath -Uncompressed:$Uncompressed},
		{
			Param ($Package)

			[TinyUIFixPSForTS3]::WriteLineQuickly("Saving$(if (-not $Uncompressed) {' and compressing'}) the generated UI-scaled package.$(if (-not $Uncompressed) {' (The compression may take dozens of seconds.)'})")

			$Package.SaveAs($Global:ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath))
		},
		{Param ($Package) [s3pi.Package.Package]::ClosePackage(1, $Package)}
	) > $Null
}


function Write-PackageForSims3Installation ([String] $Sims3Path, [String] $Sims3UserDataPath, $State, [String] $FilePath, $OutputUnpackedAssemblyDirectoryPath, [Switch] $Uncompressed, [Switch] $IsMacOSInstallation)
{
	$ResourcesToPatch = Find-ResourcesToPatch (Resolve-ResourcePrioritiesForSims3InstallationForUIScaling $Sims3Path $Sims3UserDataPath -IsMacOSInstallation:$IsMacOSInstallation)

	Write-PackageWithPatchedResources `
		-UnpatchedResources $ResourcesToPatch `
		-UnpatchedResourcesByPackage (Group-ResourcesToPatchByPackage $ResourcesToPatch) `
		-State $State `
		-FilePath $FilePath `
		-OutputUnpackedAssemblyDirectoryPath $OutputUnpackedAssemblyDirectoryPath `
		-Uncompressed:$Uncompressed
}


function Test-FingerprintForFile ($Fingerprint, $File)
{
	     $File.Length -eq $Fingerprint.FileSize `
	-and $Fingerprint.SHA256Hash -ceq (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
}


function Use-FileWhatIsDownloadedIfNecessary ($FileDescription, $DestinationDirectoryPath, $UseFile)
{
	try
	{
		$DestinationPath = Join-Path $DestinationDirectoryPath $FileDescription.FileName
		$PatchFileIsTemporary = $False

		if (Test-Path -LiteralPath $DestinationPath -PathType Leaf)
		{
			$DestinationPath = (New-TemporaryFile).FullName
			$PatchFileIsTemporary = $True
		}

		foreach ($URL in $FileDescription.URLs)
		{
			if ($URL -is [Collections.IDictionary])
			{
				$ActualURL = $URL.URL
				$UserAgent = $URL.UserAgent
			}
			else
			{
				$ActualURL = $URL
				$UserAgent = $Null
			}

			Write-Host "$([Environment]::NewLine)Downloading $($FileDescription.FileName) from $ActualURL, please stand-by as it downloads."

			$ExtraWebRequestArguments = @{}

			if ($Null -ne $UserAgent)
			{
				$ExtraWebRequestArguments.UserAgent = $UserAgent
			}

			Invoke-WebRequest -UseBasicParsing -Uri $ActualURL -OutFile $DestinationPath -ErrorAction Continue @ExtraWebRequestArguments

			if ($?)
			{
				$DownloadedFile = Get-Item -LiteralPath $DestinationPath -ErrorAction Stop
				$Fingerprint = $FileDescription.Fingerprint

				if (Test-FingerprintForFile $Fingerprint $DownloadedFile)
				{
					Write-Host "$([Environment]::NewLine)$($FileDescription.FileName) was downloaded successfully from $ActualURL."

					break
				}
				else
				{
					Write-Warning "$([Environment]::NewLine)`"$($DownloadedFile.FullName)`" downloaded from $ActualURL either: did not match the expected file-size of $($Fingerprint.FileSize)-bytes, or did not match the expected SHA-256 hash of $($Fingerprint.SHA256Hash). The file may have been corrupted, or tampered with."
				}
			}
			else
			{
				$DownloadedFile = $Null
			}
		}

		if ($Null -eq $DownloadedFile)
		{
			$ErrorMessage = "$($FileDescription.FileName) could not be downloaded from any of these URLs: $($FileDescription.URLs -join '; ')."

			if ($Script:NonInteractive)
			{
				throw [TinyUIFixPSForTS3FailedToDownloadFileException]::new($ErrorMessage, [PSCustomObject] @{FileName = $FileDescription.FileName; DestinationPath = $DestinationPath; URLsTried = $FileDescription.URLs})
			}
			else
			{
				Write-Warning "$([Environment]::NewLine)$ErrorMessage. As such, it was not installed."

				return
			}
		}

		& $UseFile $DownloadedFile $FileDescription
	}
	finally
	{
		if ($PatchFileIsTemporary -and $Null -ne $DestinationPath)
		{
			Remove-Item -LiteralPath $DestinationPath -ErrorAction Ignore
		}
	}
}


$S3PIByPeterJonesFileDescription = [PSCustomObject] @{
	FileName = 's3pi_17-0520-1823.7z'
	Fingerprint = [PSCustomObject] @{FileSize = 326771; SHA256Hash = '4597FCD8119D8E4D4DAF40C80EEF0C72CFCEFFF05315E526D40189A3BDAED804'}
	URLs = @(
		@{URL = 'https://sourceforge.net/projects/s3pi/files/17-0520-1823/s3pi_17-0520-1823.7z/download'; UserAgent = 'Wget/2.1.0'}
		'https://web.archive.org/web/20231221192710/https://master.dl.sourceforge.net/project/s3pi/17-0520-1823/s3pi_17-0520-1823.7z?viasf=1'
	)
}


$7ZipWindowsFileDescription = [PSCustomObject] @{
	FileName = '7zr.exe'
	Fingerprint = [PSCustomObject] @{FileSize = 584704; SHA256Hash = '72C98287B2E8F85EA7BB87834B6CE1CE7CE7F41A8C97A81B307D4D4BF900922B'}
	URLs = @(
		'https://github.com/ip7z/7zip/releases/download/23.01/7zr.exe'
		'https://web.archive.org/web/20231221191331/https://objects.githubusercontent.com/github-production-release-asset-2e65be/466446150/f09b4051-89b1-4b58-b683-02df8a000f40?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20231221%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231221T191331Z&X-Amz-Expires=300&X-Amz-Signature=efbd58553519009dcd853356bdd1e45275a2bd5cd7447bf6216894667591f332&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=466446150&response-content-disposition=attachment%3B%20filename%3D7zr.exe&response-content-type=application%2Foctet-stream'
	)
}


$7ZipMacOSFileDescription = [PSCustomObject] @{
	FileName = '7z2301-mac.tar.xz'
	Fingerprint = [PSCustomObject] @{FileSize = 1805532; SHA256Hash = '343EAE9CCBBD8F68320ADAAA3C87E0244CF39FAD0FBEC6B9D2CD3E5B0F8A5FBF'}
	URLs = @(
		'https://github.com/ip7z/7zip/releases/download/23.01/7z2301-mac.tar.xz'
		'https://web.archive.org/web/20231221192206/https://objects.githubusercontent.com/github-production-release-asset-2e65be/466446150/05b42ffa-3973-4425-93e7-d162d91d918d?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20231221%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231221T192205Z&X-Amz-Expires=300&X-Amz-Signature=d68460890575ff364a362624a0bc2735654ade30cd41ff20fb990cc9243039f7&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=466446150&response-content-disposition=attachment%3B%20filename%3D7z2301-mac.tar.xz&response-content-type=application%2Foctet-stream'
	)
}



function Read-YesOrNo ($Prompt)
{
	$Host.UI.PromptForChoice($Null, $Prompt, ('&Yes', '&No'), 0) -eq 0
}


function Invoke-Configurator ($DesiredPort, $PageContents, $State)
{
	$ConfiguratorInvocationResult = $Null
	$ShouldExitAfterConfigurator = $False
	$UTF8 = [Text.UTF8Encoding]::new($False, $False)
	$CurrentConfiguratorPort = if ($Null -eq $DesiredPort) {49603} else {$DesiredPort}

	$IndexPageScriptBlock = [ScriptBlock]::Create($PageContents.Index)

	$Listener = $Null

	for (;;)
	{
		try
		{
			$Listener = [Net.HttpListener]::new()
			$CurrentConfiguratorPrefix = "http://127.0.0.1:$CurrentConfiguratorPort/"
			$Listener.Prefixes.Add($CurrentConfiguratorPrefix)

			$OriginalTreatControlCAsInput = [Console]::TreatControlCAsInput
			[Console]::TreatControlCAsInput = $True

			$Listener.Start()
		}
		catch [Net.HttpListenerException]
		{
			[Console]::TreatControlCAsInput = $OriginalTreatControlCAsInput

			if ($_.Exception.ErrorCode -ne 0x000000B7)
			{
				throw
			}

			if ($Null -ne $DesiredPort)
			{
				throw [TinyUIFixPSForTS3UnableToUseConfiguratorPortException]::new("Port $DesiredPort could not be used. Perhaps, it is already in use?", [PSCustomObject] @{StartingPort = $DesiredPort; PortsTriedCount = 1})
			}

			$LastPort = $CurrentConfiguratorPort

			if (($CurrentConfiguratorPort++) -eq 65535)
			{
				throw [TinyUIFixPSForTS3UnableToUseConfiguratorPortException]::new('Ports 49603-through-to-65535 could not be used. Are they all in use?', [PSCustomObject] @{StartingPort = 49603; PortsTriedCount = 15936})
			}

			Write-Verbose "Port $LastPort was in use, so we're trying port $CurrentConfiguratorPort."

			continue
		}

		break
	}

	try
	{
		$ConfiguratorMessageLeft = 0
		$ConfiguratorMessageTop = 0

		function Write-ConfiguratorMessage
		{
			[Console]::Write("The configurator is available at the URL: $CurrentConfiguratorPrefix`nYou can:`n`tPress [Enter], or [O] to open the URL in the default web-browser.`n`tOr, open the URL manually.`n`tOr, close the configurator by pressing [Q], [Ctrl+C], or [Ctrl+Z].`n`tOr, cancel the package generation altogether by pressing [Ctrl+D].`n`n")

			[Console]::CursorLeft
			[Console]::CursorTop
		}

		function Remove-ConfiguratorMessage
		{
			[Console]::SetCursorPosition($ConfiguratorMessageLeft, $ConfiguratorMessageTop)
			[Console]::Write("                                          $(' ' * $CurrentConfiguratorPrefix.Length)`n        `n`t                                                                 `n`t                          `n`t                                                                  `n`t                                                                  `n`n")
			[Console]::SetCursorPosition($ConfiguratorMessageLeft, $ConfiguratorMessageTop)
		}

		$ConfiguratorMessageLeft, $ConfiguratorMessageTop = Write-ConfiguratorMessage

		for (;;)
		{
			$ShouldProceed = $False
			$ShouldStop = $False
			$ContextTask = $Listener.GetContextAsync()

			:PollForCompletionOrCancellation for (;;)
			{
				while ([Console]::KeyAvailable)
				{
					$Key = [Console]::ReadKey($True)

					if ($Key.Modifiers -eq 0)
					{
						if ($Key.Key -eq [ConsoleKey]::Q)
						{
							$ShouldStop = $True
							break PollForCompletionOrCancellation
						}
						elseif ($Key.Key -eq [ConsoleKey]::Enter -or $Key.Key -eq [ConsoleKey]::O)
						{
							try
							{
								Start-Process -FilePath $CurrentConfiguratorPrefix -ErrorAction Continue
							}
							catch
							{
								Remove-ConfiguratorMessage
								Write-Error $_ -ErrorAction Continue
								$ConfiguratorMessageLeft, $ConfiguratorMessageTop = Write-ConfiguratorMessage
							}
						}
					}
					elseif ($Key.Modifiers -eq [ConsoleModifiers]::Control)
					{
						if ($Key.Key -eq [ConsoleKey]::C -or $Key.Key -eq [ConsoleKey]::Z)
						{
							$ShouldStop = $True
							break PollForCompletionOrCancellation
						}
						elseif ($Key.Key -eq [ConsoleKey]::D)
						{
							$ShouldExitAfterConfigurator = $True
							$ShouldStop = $True
							break PollForCompletionOrCancellation
						}
					}
				}

				if ($ContextTask.IsCompleted)
				{
					if ($ContextTask.IsFaulted)
					{
						Remove-ConfiguratorMessage
						Write-Error $ContextTask.Exception -ErrorAction Continue
						$ConfiguratorMessageLeft, $ConfiguratorMessageTop = Write-ConfiguratorMessage
					}
					else
					{
						$Context = $ContextTask.Result
						$ShouldProceed = $True
					}

					break PollForCompletionOrCancellation
				}

				$ContextTask.Wait(1) > $Null
			}

			if ($ShouldStop)
			{
				$Listener.Abort()

				break
			}

			if (-not $ShouldProceed)
			{
				continue
			}

			function Start-HTMLResponse ([String] $HTML)
			{
				$Context.Response.ContentEncoding = $UTF8
				$Context.Response.ContentType = 'text/html; charset=utf8'

				$Context.Response.Headers.Add('Content-Security-Policy', "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src 'self'; font-src 'none'; connect-src 'self'; media-src 'self'; object-src 'none'; child-src 'self'; frame-src 'self'; worker-src 'none'; frame-ancestors 'self'; form-action 'self'; base-uri 'self'")
				$Context.Response.Headers.Add('X-Content-Type-Options', 'nosniff')
				$Context.Response.Headers.Add('X-Frame-Options', 'SAMEORIGIN')
				$Context.Response.Headers.Add('X-XSS-Protection', '1; mode=block')
				$Context.Response.Headers.Add('Referrer-Policy', 'same-origin')
				$Context.Response.Headers.Add('Feature-Policy', "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'none'; camera 'none'; document-domain 'none'; document-write 'none'; encrypted-media 'none'; fullscreen 'none'; geolocation 'none'; gyroscope 'none'; legacy-image-formats 'none'; magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture 'none'; speaker 'none'; usb 'none'; vr 'none'")

				$ResponseBody = $UTF8.GetBytes($HTML)
				$Context.Response.ContentLength64 = $ResponseBody.Length
				$Context.Response.OutputStream.Write($ResponseBody, 0, $ResponseBody.Length)
			}

			function Send-Response
			{
				$Context.Response.Close()
			}

			function Read-RequestBody
			{
				try
				{
					$BodyStream = [IO.StreamReader]::new($Context.Request.InputStream, $Context.Request.ContentEncoding)
					$BodyStream.ReadToEnd()
				}
				finally
				{
					$BodyStream.Close()
				}
			}

			try
			{
				if ($Context.Request.HttpMethod -eq 'GET' -and $Context.Request.Url.AbsolutePath -eq '/')
				{
					Start-HTMLResponse (& $IndexPageScriptBlock -State $State)

					Send-Response
				}
				elseif ($Context.Request.HttpMethod -eq 'POST' -and $Context.Request.Url.AbsolutePath -eq '/generate-package')
				{
					$ConvertFromJsonArguments = if ($PSVersionTable.PSVersion.Major -le 5) {@{}} else {@{Depth = 100; AsHashtable = $True}}
					$RequestBody = ConvertFrom-Json (Read-RequestBody) @ConvertFromJsonArguments
					$ConfiguratorInvocationResult = @{RequestBody = $RequestBody}

					$Context.Response.StatusCode = 204

					Send-Response

					break
				}
				elseif ($Context.Request.HttpMethod -eq 'POST' -and $Context.Request.Url.AbsolutePath -eq '/cancel')
				{
					$ShouldExitAfterConfigurator = $True

					$Context.Response.StatusCode = 204

					Send-Response

					break
				}
				else
				{
					$Context.Response.StatusCode = 404

					Send-Response
				}
			}
			catch
			{
				Remove-ConfiguratorMessage
				Write-Error $_.Exception.ToString() -ErrorAction Continue
				$ConfiguratorMessageLeft, $ConfiguratorMessageTop = Write-ConfiguratorMessage

				$Context.Response.StatusCode = 500

				Send-Response
			}
		}

		$Listener.Close()
	}
	catch
	{
		$Listener.Abort()

		Write-Error $_ -ErrorAction Continue
	}
	finally
	{
		[Console]::TreatControlCAsInput = $OriginalTreatControlCAsInput
	}

	if ($ShouldExitAfterConfigurator)
	{
		exit
	}

	if ($Null -eq $ConfiguratorInvocationResult)
	{
		@{Cancelled = $True}
	}
	else
	{
		$ConfiguratorInvocationResult
	}
}


if ($Script:MyInvocation.InvocationName -ceq '.' -or $Script:MyInvocation.Line -ceq '')
{
	return
}


$UsingConfigurator = -not $NonInteractive -and -not $SkipConfigurator
$CheckingIfPatchsetsAreRecommended = $UsingConfigurator -or $GetPatchsetRecommendations
$ResolvingResourcePriorities = -not $SkipGenerationOfPackage -or $GetResolvedPackagePriorities -or $UsingConfigurator -or $CheckingIfPatchsetsAreRecommended
$FindingSims3Paths = $ResolvingResourcePriorities
$ShouldLoadInactivePatchsets = $UsingConfigurator -or $CheckingIfPatchsetsAreRecommended
$ShouldLoadPatchsets = $UsingConfigurator -or -not $SkipGenerationOfPackage -or $GetStatusOfPatchsets -or $CheckingIfPatchsetsAreRecommended -or $ShouldLoadInactivePatchsets
$ShouldReadPatchsets = $ShouldLoadPatchsets -or $ShouldLoadInactivePatchsets -or $GetAvailablePatchsets -or $CheckingIfPatchsetsAreRecommended


$LastPatchsetLoadOrderFilePath = Join-Path $PSScriptRoot LastPatchsetLoadOrder.txt
$LastPatchsetConfigurationFilePath = Join-Path $PSScriptRoot LastPatchsetConfiguration.json


$LoadOrderNotExplicitlySetByUser = $Null -eq $Script:PSBoundParameters.PatchsetLoadOrder


if ($Null -eq $PatchsetLoadOrder -and (Test-Path -LiteralPath $LastPatchsetLoadOrderFilePath))
{
	[TinyUIFixPSForTS3]::WriteLineQuickly("Reading the load-order for patchsets from `"$LastPatchsetLoadOrderFilePath`".")

	$LastLoadOrder = Get-Content -Raw -LiteralPath $LastPatchsetLoadOrderFilePath -ErrorAction Continue

	if ($Null -ne $LastLoadOrder)
	{
		$PatchsetLoadOrder = ($LastLoadOrder -split '\s+').Where{$_}
		$LoadOrderNotExplicitlySetByUser = $False
	}
}


if ($Null -eq $PatchsetConfiguration -and (Test-Path -LiteralPath $LastPatchsetConfigurationFilePath))
{
	[TinyUIFixPSForTS3]::WriteLineQuickly("Reading the configurations for patchsets from `"$LastPatchsetConfigurationFilePath`".")

	$LastConfiguration = Get-Content -Raw -LiteralPath $LastPatchsetConfigurationFilePath -ErrorAction Continue

	if ($Null -ne $LastConfiguration)
	{
		$ConvertFromJsonArguments = if ($PSVersionTable.PSVersion.Major -le 5) {@{}} else {@{Depth = [TinyUIFixPSForTS3]::MaximumPatchsetConfigurationFileDepth; AsHashtable = $True}}
		$ParsedLastConfiguration = ConvertFrom-Json $LastConfiguration @ConvertFromJsonArguments -ErrorAction Continue

		if ($Null -ne $ParsedLastConfiguration)
		{
			$PatchsetConfiguration = if ($PSVersionTable.PSVersion.Major -le 5)
			{
				[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary([Ordered] @{}, $ParsedLastConfiguration)
			}
			else
			{
				$ParsedLastConfiguration
			}
		}
	}
}


if ($Null -eq $PatchsetConfiguration)
{
	$PatchsetConfiguration = @{}
}


if ($UsingConfigurator)
{
	$DataPath = Join-Path $PSScriptRoot Data
	$ReadConfiguratorIndexPageTask = [IO.StreamReader]::new(
		[IO.FileStream]::new((Join-Path $DataPath ConfiguratorIndexPage.ps1), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete),
		[Text.UTF8Encoding]::new($False, $False)
	).ReadToEndAsync()
}


if ($ShouldReadPatchsets -and -not (Test-RequiredDBPFManipulationTypesAreLoaded))
{
	Find-DBPFManipulationAssemblies | % {Add-Type -LiteralPath $_.FullName}

	if (-not $NonInteractive)
	{
		if (-not (Test-RequiredDBPFManipulationTypesAreLoaded))
		{
			if ($IsWindowsOrMacOS)
			{
				if (Read-YesOrNo "To manipulate Sims 3 package files this program requires a library with an S3PI-compatible interface: no such library was found on this computer.$([Environment]::NewLine)Would you like to download S3PI by Peter Jones (https://s3pi.sourceforge.net) now?")
				{
					$BinariesPath = Join-Path $PSScriptRoot Binaries
					$7zCommandNames = if ($IsWindows) {'7zr', '7z'} else {'7zz'}
					$7z = $Null

					if ($Null -eq $7zCommandNames.Where({Test-Path -LiteralPath ($7z = Join-Path $BinariesPath $_)}, 'First')[0] -and $Null -eq $7zCommandNames.Where({($7z = (Get-Command $_ -ErrorAction Ignore).Source)}, 'First')[0])
					{
						if (Read-YesOrNo "7-zip is required to extract a downloaded copy of S3PI by Peter Jones: 7-zip was not found on this computer.$([Environment]::NewLine)Would you like to download 7-zip by Igor Pavlov (https://www.7-zip.org) now?")
						{
							if ($IsWindows)
							{
								$7z = Use-FileWhatIsDownloadedIfNecessary $7ZipWindowsFileDescription $BinariesPath `
								{
									Param ($File, $Description)
									$File.FullName
								}
							}
							else
							{
								$7z = Use-FileWhatIsDownloadedIfNecessary $7ZipMacOSFileDescription $BinariesPath `
								{
									Param ($File, $Description)
									tar -x -J -C $BinariesPath -s /^License\.txt$/7zz_License.txt/ -f $File.FullName -- 7zz License.txt
									Join-Path $BinariesPath 7zz
								}
							}

							Unblock-File -LiteralPath $7z
						}
					}

					$DBPFPath = Join-Path $BinariesPath DBPF
					New-Item -ItemType Directory -Force -Path $DBPFPath > $Null

					Use-FileWhatIsDownloadedIfNecessary $S3PIByPeterJonesFileDescription $DBPFPath `
					{
						Param ($File, $Description)

						& $7z x "-o$DBPFPath" -- $File.FullName > $Null

						Find-DBPFManipulationAssemblies $DBPFPath | % {Add-Type -LiteralPath $_.FullName}
					}
				}
			}
			else
			{
				Write-Host "To manipulate Sims 3 package files this program requires a library with an S3PI-compatible interface: no such library was found on this computer.$([Environment]::NewLine)This program would offer to download S3PI by Peter Jones (https://s3pi.sourceforge.net) for you, but that feature is implemented only for Windows and macOS."
			}
		}
	}

	Initialize-TinyUIFixResourceKeys
}


$UltimateResult = @{}


if ($Null -ne $Script:PSBoundParameters.InstallationPlatform)
{
	if ($InstallationPlatform -eq 'macOS')
	{
		$IsMacOSInstallation = $True
	}
	elseif ($InstallationPlatform -eq 'Windows')
	{
		$IsMacOSInstallation = $False
	}
	else
	{
		Write-Error "`"$InstallationPlatform`" is not a valid value for the InstallationPlatform parameter. It must be either `"Windows`" or `"macOS`"." -ErrorAction Stop
	}
}
else
{
	$IsMacOSInstallation = $IsMacOS
}


$PatchingState = New-PatchingState


if ($ShouldReadPatchsets)
{
	[TinyUIFixPSForTS3]::WriteLineQuickly("Reading patchsets from `"$(Join-Path $PSScriptRoot Patchsets)`".")

	$AvailablePatchsets = Read-AvailablePatchsets

	if ($GetAvailablePatchsets)
	{
		$UltimateResult.AvailablePatchsets = $AvailablePatchsets
	}
}


if ($ShouldLoadPatchsets)
{
	[TinyUIFixPSForTS3]::WriteLineQuickly('Resolving the load-order for patchsets.')

	$LoadOrder = Resolve-PatchsetLoadOrder $PatchsetLoadOrder $AvailablePatchsets.PatchsetsByID -LoadOrderNotExplicitlySetByUser:$LoadOrderNotExplicitlySetByUser
	$LoadedPatchsets = Load-Patchsets $AvailablePatchsets -State $PatchingState -LoadOrder $LoadOrder -ConfigurationObject $PatchsetConfiguration

	if ($GetStatusOfPatchsets)
	{
		$UltimateResult.PatchsetStatus = [PSCustomObject] @{
			LoadOrder = $LoadOrder
			Active = $LoadedPatchsets.Patchsets
			FailedToImport = $LoadedPatchsets.FailedToImport
		}
	}
}


if ($ShouldLoadInactivePatchsets)
{
	$UnloadedPatchsetIDs = $AvailablePatchsets.PatchsetsByID.Keys.Where{-not $LoadOrder.ByID.ContainsKey($_)}
	$ImportedInactivePatchsets = Import-Patchsets $AvailablePatchsets.PatchsetsByID @{ByIndex = $UnloadedPatchsetIDs}

	foreach ($FailedImport in $ImportedInactivePatchsets.FailedToImport)
	{
		Write-Error -ErrorAction Continue "An error occurred when loading the patchset at `"$($FailedImport.Item1)`". The error was:$([Environment]::NewLine)$($FailedImport.Item2)"
	}

	foreach ($Patchset in $ImportedInactivePatchsets.Patchsets)
	{
		if ($Patchset.Instance.InitialiseAfterLoading -is [ScriptBlock])
		{
			[TinyUIFixPSForTS3]::WriteLineQuickly("Initialising the `"$($Patchset.Definition.ID)`" patchset after loading it.")

			$State.Logger.CurrentPatchset = $Patchset
			& $Patchset.Instance.InitialiseAfterLoading -Self $Patchset.Instance -State (New-PatchingState) > $Null
		}
	}
}


if ($FindingSims3Paths)
{
	if ($Null -eq $Script:ExpectedSims3Paths)
	{
		$Script:ExpectedSims3Paths = Get-ExpectedSims3Paths
	}

	if (-not $NonInteractive)
	{
		if (-not (Test-Sims3Path $Script:ExpectedSims3Paths.Sims3Path -IsMacOSInstallation:$IsMacOSInstallation))
		{
			$Script:ExpectedSims3Paths.Sims3Path = Read-Host 'The file-path of your installation of The Sims 3 could not be automatically found, please supply the file-path of your Sims 3 installation. (It is usually a folder named "The Sims 3")'

			if (-not (Test-Path $Script:ExpectedSims3Paths.Sims3Path))
			{
				Write-Warning "That path doesn't seem correct, as no `"$(Join-Path $Script:ExpectedSims3Paths.Sims3Path $(if ($IsMacOSInstallation) {'Contents/Resources/Resource.cfg'} else {'Game/Bin/Resource.cfg'}))`" file could be found at that path."
			}
		}

		if (-not (Test-Sims3UserDataPath $Script:ExpectedSims3Paths.Sims3UserDataPath))
		{
			$Script:ExpectedSims3Paths.Sims3UserDataPath = Read-Host 'The file-path of your user-data folder for The Sims 3 could not be automatically found, please supply the file-path of your user-data folder for The Sims 3. (It is usually a folder named "The Sims 3", and is where mods are typically installed)'

			if (-not (Test-Path $Script:ExpectedSims3Paths.Sims3UserDataPath))
			{
				Write-Warning "That path doesn't seem correct, as no `"$(Join-Path $Script:ExpectedSims3Paths.Sims3UserDataPath Options.ini)`" file could be found at that path."
			}
		}
	}
}


$ModsPath = Join-Path $Script:ExpectedSims3Paths.Sims3UserDataPath Mods
$OverridesPath = Join-Path $ModsPath Overrides
$ResourceCFGPath = Join-Path $ModsPath Resource.cfg
$TinyUIFixModFolderPath = Join-Path $ModsPath ([TinyUIFixPSForTS3]::ModsFolderName)


if (-not $SkipGenerationOfPackage)
{
	$OldGeneratedPackageFilePath = Join-Path $OverridesPath ([TinyUIFixPSForTS3]::GeneratedPackageName)
	<# Version 1.0.3-and-older of this mod stored the package in the Overrides folder, so we delete it
	   to prevent new installations from conflicting with old installations. #>
	Remove-Item -LiteralPath $OldGeneratedPackageFilePath -Force -ErrorAction Ignore
}


if ($ResolvingResourcePriorities)
{
	$ResolvedResourcesPriorities = Resolve-ResourcePrioritiesForSims3InstallationForUIScaling $Script:ExpectedSims3Paths.Sims3Path $Script:ExpectedSims3Paths.Sims3UserDataPath -IsMacOSInstallation:$IsMacOSInstallation
}


if ($CheckingIfPatchsetsAreRecommended)
{
	$PatchsetRecommendationsByID = @{}

	$CheckPatchsetRecommendations = `
	{
		Param ($PatchsetsByID)

		foreach ($Patchset in $PatchsetsByID.Values)
		{
			$Recommendation = Test-PatchsetIsRecommended $Patchset $ResolvedResourcesPriorities.AllActiveModPackages

			if ($Recommendation.IsRecommended)
			{
				$PatchsetRecommendationsByID[$Patchset.Definition.ID] = $Recommendation
			}
		}
	}

	& $CheckPatchsetRecommendations $LoadedPatchsets.Patchsets
	& $CheckPatchsetRecommendations $ImportedInactivePatchsets.Patchsets

	if ($GetPatchsetRecommendations)
	{
		$UltimateResult.PatchsetRecommendationsByID = $PatchsetRecommendationsByID
	}
}


if ($GetResolvedPackagePriorities)
{
	$FilesWithUnpackedPriorities = foreach ($Entry in $ResolvedResourcesPriorities.PrioritisedFiles.GetEnumerator())
	{
		$Unpacked = [TinyUIFixPSForTS3]::UnpackPriority($Entry.Key)
		[PSCustomObject] @{Priority = $Unpacked.Item1; Depth = $Unpacked.Item2; IsMod = $Unpacked.Item3; Files = $Entry.Value}
	}

	$ResolvedResourcesPrioritiesOutput = [PSCustomObject] @{
		GameBinDirectory = $ResolvedResourcesPriorities.GameBinDirectory
		GameSharedDirectory = $ResolvedResourcesPriorities.GameSharedDirectory
		ModsDirectory = $ResolvedResourcesPriorities.ModsDirectory
		FilesByPackedPriority = $ResolvedResourcesPriorities.PrioritisedFiles
		FilesWithUnpackedPriorities = $FilesWithUnpackedPriorities
		AllActiveModPackages = $ResolvedResourcesPriorities.AllActiveModPackages
	}

	$UltimateResult.ResolvedPackagePriorities = $ResolvedResourcesPrioritiesOutput
}


if ($SkipGenerationOfPackage -and -not $UsingConfigurator)
{
	return [PSCustomObject] $UltimateResult
}


if ($UsingConfigurator)
{
	$AvailablePatchsetsForConfigurator = [Collections.Generic.List[PSCustomObject]]::new()

	$AddPatchsets = `
	{
		Param ($PatchsetsByID)

		foreach ($Patchset in $PatchsetsByID.Values)
		{
			$AvailablePatchsetsForConfigurator.Add(
				$(
					$Name = $Patchset.Instance.FriendlyName
					$Description = $Patchset.Instance.Description

					if (-not ($Name -is [String]))
					{
						$Name = if ($Null -eq $Name) {$Patchset.Definition.ID} else {try {$Name.ToString()} catch {$Patchset.Definition.ID}}
					}

					if (-not ($Description -is [String]))
					{
						$Description = if ($Null -eq $Description) {[String]::Empty} else {try {$Description.ToString()} catch {[String]::Empty}}
					}

					$Data = @{
						ID = $Patchset.Definition.ID
						Version = $Patchset.Definition.Version
						Name = $Name
						Description = $Description
					}

					$Recommendation = $PatchsetRecommendationsByID[$Patchset.Definition.ID]

					if ($LoadOrder.ByID.ContainsKey($Patchset.Definition.ID)) {$Data.Active = $True}
					if ($Patchset.Definition.ID -eq 'Nucleus') {$Data.FixedActiveState = $True}
					if ($Null -ne $Recommendation) {$Data.RecommendationMessage = $Recommendation.RecommendationMessage}

					$Data
				)
			)
		}
	}

	& $AddPatchsets $LoadedPatchsets.Patchsets
	& $AddPatchsets $ImportedInactivePatchsets.Patchsets

	$AvailablePatchsetsForConfigurator = $AvailablePatchsetsForConfigurator | Sort-Object -Property @{
		Expression = {"$(if ($_.ID -eq 'Nucleus') {0} elseif ($_.ID -eq 'VanillaCoreCompatibilityPatch') {1} else {2})$($_.Name)$($_.ID)"}
	}

	[TinyUIFixPSForTS3]::WriteLineQuickly([Environment]::NewLine)

	$ConfiguratorInvocation = Invoke-Configurator `
		-Port $(if ($Null -ne $Script:PSBoundParameters.ConfiguratorPort) {$ConfiguratorPort}) `
		-PageContents @{Index = $ReadConfiguratorIndexPageTask.GetAwaiter().GetResult()} `
		-State @{
			UIScale = $PatchingState.Configuration.Nucleus.UIScale
			LoadOrder = $LoadOrder
			AvailablePatchsets = $AvailablePatchsetsForConfigurator
		} `
		-Actions @{
			GeneratePackage = `
			{
				@{StopListening = $True; Result = 'abc'}
			}
		}

	if (-not $ConfiguratorInvocation.Cancelled)
	{
		$ConfiguratorLoadOrder = $ConfiguratorInvocation.RequestBody.patchsetLoadOrder -split '\s+'
		[TinyUIFixPSForTS3]::RecursivelyMergeIntoDictionary($PatchsetConfiguration, $ConfiguratorInvocation.RequestBody.patchsetConfiguration) > $Null

		$LoadOrder = Resolve-PatchsetLoadOrder $ConfiguratorLoadOrder $AvailablePatchsets.PatchsetsByID
		$PatchingState = New-PatchingState
		$LoadedPatchsets = Load-Patchsets $AvailablePatchsets -State $PatchingState -LoadOrder $LoadOrder -ConfigurationObject $PatchsetConfiguration
	}
}


New-Item $LastPatchsetLoadOrderFilePath -Force -Value "$($LoadOrder.ByIndex -join ([Environment]::NewLine))$([Environment]::NewLine)" > $Null
New-Item $LastPatchsetConfigurationFilePath -Force -Value "$(ConvertTo-Json $PatchsetConfiguration -Depth ([TinyUIFixPSForTS3]::MaximumPatchsetConfigurationFileDepth))$([Environment]::NewLine)" > $Null


if ($SkipGenerationOfPackage)
{
	return [PSCustomObject] $UltimateResult
}


$PrependToFile = `
{
	Param ($FilePath, $Text)

	$UTF8 = [Text.UTF8Encoding]::new($False, $False)

	try
	{
		$ExistingData = [IO.File]::ReadAllBytes($FilePath)
	}
	catch [IO.FileNotFoundException]
	{
		$ExistingData = [Byte[]] @()
	}

	$ConcatenatedData = $UTF8.GetBytes($Text) + $ExistingData
	[IO.File]::WriteAllBytes($FilePath, $ConcatenatedData)
}


if (-not (Test-Path -LiteralPath $ResourceCFGPath))
{
	New-Item -ItemType Directory -Force -Path $ModsPath -ErrorAction Stop > $Null

	[TinyUIFixPSForTS3]::WriteLineQuickly("A Resource.cfg file for mods could not be found, so one is being created one at: `"$ResourceCFGPath`".")

	$SeedResourceCFG = "Priority 10000$([Environment]::NewLine)PackedFile $([TinyUIFixPSForTS3]::GeneratePackagePackedFileDirective)$([Environment]::NewLine)Priority 0"
	& $PrependToFile $ResourceCFGPath "$SeedResourceCFG$([Environment]::NewLine)"
}
else
{
	$ResourceCFGLines = [String[]] (Get-Content -LiteralPath $ResourceCFGPath -ErrorAction Stop)
	$PackedFileDirectives = [TinyUIFixPSForTS3]::ExtractPackedFileDirectivesFromResourceCFG($ResourceCFGLines)
	$GreatestPriority = 0
	$HaveTinyUIFixDirective = $False

	foreach ($PackedFileDirective in $PackedFileDirectives)
	{
		if ($PackedFileDirective.Item2 -gt $GreatestPriority)
		{
			$GreatestPriority = $PackedFileDirective.Item2
		}

		if (-not $HaveTinyUIFixDirective -and $PackedFileDirective.Item1 -eq [TinyUIFixPSForTS3]::GeneratePackagePackedFileDirective)
		{
			$HaveTinyUIFixDirective = $True
		}
	}

	if (-not $HaveTinyUIFixDirective)
	{
		[TinyUIFixPSForTS3]::WriteLineQuickly("`"$ResourceCFGPath`" does not have a PackedFileDirective for the Tiny UI Fix's generated package, so a PackedFileDirective for it is being added to the file.")

		$Adjustment = [Int32]::MaxValue - $GreatestPriority
		if ($Adjustment -gt 100) {$Adjustment = 100}
		$NewPriority = $GreatestPriority + $Adjustment

		$SeedResourceCFG = "Priority $NewPriority$([Environment]::NewLine)PackedFile $([TinyUIFixPSForTS3]::GeneratePackagePackedFileDirective)$([Environment]::NewLine)Priority 0"
		& $PrependToFile $ResourceCFGPath "$SeedResourceCFG$([Environment]::NewLine)$([Environment]::NewLine)"
	}
}

if (-not (Test-Path -LiteralPath $TinyUIFixModFolderPath))
{
	New-Item -ItemType Directory -Force -Path $TinyUIFixModFolderPath -ErrorAction Stop > $Null
}

$GeneratedPackageFilePath = Join-Path $TinyUIFixModFolderPath ([TinyUIFixPSForTS3]::GeneratedPackageName)


$ResourcesToPatch = Find-ResourcesToPatch $ResolvedResourcesPriorities
$ResourcesToPatchByPackage = Group-ResourcesToPatchByPackage $ResourcesToPatch

Write-PackageWithPatchedResources `
	-UnpatchedResources $ResourcesToPatch `
	-UnpatchedResourcesByPackage $ResourcesToPatchByPackage `
	-State $PatchingState `
	-FilePath $GeneratedPackageFilePath `
	-OutputUnpackedAssemblyDirectoryPath $OutputUnpackedAssemblyDirectoryPath `
	-Uncompressed:$GenerateUncompressedPackage


$UltimateResult.GeneratedPackage = Get-Item -LiteralPath $GeneratedPackageFilePath -ErrorAction Continue

if ($Null -ne $UltimateResult.GeneratedPackage)
{
	if (-not $NonInteractive -or $ChangeResourceCFGToLoadTinyUIFixLast)
	{
		$FinalResolvedResourcesPriorities = Resolve-ResourcePrioritiesForSims3InstallationForUIScaling $Script:ExpectedSims3Paths.Sims3Path $Script:ExpectedSims3Paths.Sims3UserDataPath -IsMacOSInstallation:$IsMacOSInstallation -IncludeTinyUIFixPackage
		$PrioritiesInReverse = $FinalResolvedResourcesPriorities.PrioritisedFiles.Keys | Sort-Object -Descending
		$TinyUIFixPackagePath = $UltimateResult.GeneratedPackage.FullName
		$PriorityToBeat = $Null
		$ScaledPackagesThatAreOverwritingTinyUIFix = [Collections.Generic.List[String]]::new(0)

		:ForEachPriority foreach ($Priority in $PrioritiesInReverse)
		{
			$Files = $FinalResolvedResourcesPriorities.PrioritisedFiles[$Priority]

			for ($Index = $Files.Count; ($Index--) -gt 0;)
			{
				$File = $Files[$Index].FullName

				if ($File -eq $TinyUIFixPackagePath)
				{
					break ForEachPriority
				}

				if ($ResourcesToPatchByPackage.ContainsKey($File))
				{
					$ScaledPackagesThatAreOverwritingTinyUIFix.Add($File)

					if ($Null -eq $PriorityToBeat)
					{
						$PriorityToBeat = $Priority
					}
				}
			}
		}

		if ($ScaledPackagesThatAreOverwritingTinyUIFix.Count -gt 0)
		{
			[TinyUIFixPSForTS3]::WriteLineQuickly([String]::Empty)
			Write-Warning "There are packages that were scaled by the Tiny UI Fix that will be loaded after the Tiny UI Fix, which will cause the scaling to not take effect.$([Environment]::NewLine)Those packages are: $(($ScaledPackagesThatAreOverwritingTinyUIFix | % {'"{0}"' -f $_}) -join '; ')." -WarningAction Continue

			$PriorityToBeat = [TinyUIFixPSForTS3]::UnpackPriority($PriorityToBeat).Item1

			if ($PriorityToBeat -eq [Int32]::MaxValue)
			{
				Write-Warning "This script would offer to adjust the Resource.cfg file for you, but a priority cannot be greater than $([Int32]::MaxValue)." -WarningAction Continue
			}
			elseif (
				$(
					$Adjustment = [Int32]::MaxValue - $PriorityToBeat
					if ($Adjustment -gt 100) {$Adjustment = 100}

					$ResourceCFGAddition = "Priority $($PriorityToBeat + $Adjustment)$([Environment]::NewLine)PackedFile $([TinyUIFixPSForTS3]::GeneratePackagePackedFileDirective)$([Environment]::NewLine)Priority 0"

					$NonInteractive -or (Read-YesOrNo "$([Environment]::NewLine)Would you like to adjust the `"$ResourceCFGPath`" file to load $([TinyUIFixPSForTS3]::GeneratedPackageName) after the scaled packages?$([Environment]::NewLine)$([Environment]::NewLine)These lines would be added to the start of Resource.cfg:$([Environment]::NewLine)$ResourceCFGAddition")
				)
			)
			{
				& $PrependToFile $ResourceCFGPath "$ResourceCFGAddition$([Environment]::NewLine)$([Environment]::NewLine)"
			}
		}
	}
}


[TinyUIFixPSForTS3]::WriteLineQuickly("$([Environment]::NewLine)A UI-scaled package file was generated, and saved to `"$GeneratedPackageFilePath`".$([Environment]::NewLine)$([Environment]::NewLine)Have fun! :)")


[PSCustomObject] $UltimateResult

