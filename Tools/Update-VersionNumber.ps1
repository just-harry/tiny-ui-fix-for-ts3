
[CmdletBinding()]
Param (
	[Parameter(Mandatory, Position = 0)]
			[Version] $Version
)


$Data = & (Join-Path $PSScriptRoot ../Data.ps1)


$AsVersionExpression = "$($Version.Major), $($Version.Minor)$(if ($Version.Build -ge 0) {", $($Version.Build)"})$(if ($Version.Revision -ge 0) {", $($Version.Revision)"})"


sed -b -i $(if ($IsMacOS) {''}) -E -e "s/(\bstatic\s*\[Version\]\s*\`$Version\s*=\s*\[Version\]::new\()[^\)]+/\1$AsVersionExpression/" -- (Join-Path $Data.TinyUIFixPatcherPath Use-TinyUIFixForTS3.ps1)
sed -b -i $(if ($IsMacOS) {''}) -E -e "s:(/releases/(download/)?)v[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?/:\1v$Version/:g" -- (Join-Path $Data.Root README.md)
sed -b -i $(if ($IsMacOS) {''}) -E -e "s/(\bAssemblyFileVersion\s*\(\s*`")[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?/\1$Version.0/" -- (Join-Path $Data.TinyUIFixPatchPath AssemblyInfo.cs)
sed -b -i $(if ($IsMacOS) {''}) -E -e "s/(\bAssemblyFileVersion\s*\(\s*`")[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?/\1$Version.0/" -- (Join-Path $Data.TinyUIFixCoreBridgePath AssemblyInfo.cs)


$RootPath = $Data.Root
$VersionPath = (Join-Path $RootPath VERSION)

git stash
git checkout most-recent-version
[IO.File]::WriteAllText($VersionPath, "$Version`r`n`r`n", [Text.UTF8Encoding]::new($False, $False))
git add -- $VersionPath
git commit --amend -m "Make note of the latest version: v$Version."
git checkout -
git stash pop

