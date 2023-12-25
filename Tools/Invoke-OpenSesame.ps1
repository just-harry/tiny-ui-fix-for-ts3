
[CmdletBinding()]
Param (
	[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
)

Begin
{
	$Data = & (Join-Path $PSScriptRoot ../Data.ps1)

	if ($Null -eq ([Management.Automation.PSTypeName] 'Mono.Cecil.AssemblyDefinition').Type)
	{
		$CecilPath = Join-Path $Data.BuildBinPath Mono.Cecil.dll

		if (-not (Test-Path -LiteralPath $CecilPath))
		{
			& (Join-Path $PSScriptRoot ../Building/Build-Cecil.ps1)
		}

		Add-Type -LiteralPath $CecilPath
	}

	if ($Null -eq ([Management.Automation.PSTypeName] 'TinyUIFixForTS3OpenSesame.Opener').Type)
	{
		$OpenSesamePath = Join-Path $Data.BuildBinPath OpenSesame.dll

		if (-not (Test-Path -LiteralPath $OpenSesamePath))
		{
			& (Join-Path $PSScriptRoot ../Building/Build-OpenSesame.ps1)
		}

		Add-Type -LiteralPath $OpenSesamePath
	}

	$Opener = [TinyUIFixForTS3OpenSesame.Opener]::new()
}

Process
{
	if ($InputObject -is [String] -or $InputObject -is [IO.FileInfo])
	{
		try
		{
			$Resolver = [Mono.Cecil.DefaultAssemblyResolver]::new()
			$Parameters = [Mono.Cecil.ReaderParameters]::new()
			$Parameters.AssemblyResolver = $Resolver

			$Resolver.AddSearchDirectory((Split-Path -LiteralPath $InputObject))

			$File = [IO.File]::Open($InputObject, 'Open', 'ReadWrite', 'Delete')

			$Assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($File, $Parameters)
			$Opener.MakeFullyPublic($Assembly)
			$Assembly.Write()

			$InputObject
		}
		finally
		{
			if ($Null -ne $File) {$File.Dispose()}
			if ($Null -ne $Resolver) {$Resolver.Dispose()}
			if ($Null -ne $Assembly) {$Assembly.Dispose()}
		}
	}
	else
	{
		$Opener.MakeFullyPublic($InputObject)

		$InputObject
	}
}

