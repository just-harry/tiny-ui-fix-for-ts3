
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

[CmdletBinding()]
Param (
	[Parameter()]
		[ValidateNotNullOrEmpty()]
			[String] $SyncObjectPrefix
)


$OverseerEvent = $Null
$MinionEvent = $Null

try
{
	$PowerShellPath = [Diagnostics.Process]::GetCurrentProcess().Path

	$OverseerEvent = [Threading.EventWaitHandle]::OpenExisting("Global\$SyncObjectPrefix-OverseerEvent")
	$MinionEvent = [Threading.EventWaitHandle]::OpenExisting("Global\$SyncObjectPrefix-MinionEvent")

	Write-Host 'Allowing PowerShell to access controlled folders.' -ErrorAction Ignore

	Add-MpPreference -ControlledFolderAccessAllowedApplications $PowerShellPath -ErrorAction Continue

	$MinionEvent.Set() > $Null

	Write-Host 'Waiting for the Tiny UI Fix to finish what it''s doing.' -ErrorAction Ignore

	$OverseerEvent.WaitOne() > $Null

	Write-Host 'Disallowing PowerShell from accessing controlled folders.' -ErrorAction Ignore

	Remove-MpPreference -ControlledFolderAccessAllowedApplications $PowerShellPath -ErrorAction Continue

	$MinionEvent.Set() > $Null
}
finally
{
	if ($Null -ne $OverseerEvent) {$OverseerEvent.Dispose()}
	if ($Null -ne $MinionEvent) {$MinionEvent.Dispose()}
}

