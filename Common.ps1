
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>


if ($Null -eq $PSNativeCommandArgumentPassing)
{
	$PSNativeCommandArgumentPassing = 'Legacy'
}


function ForEach-InParallel ($InputObject, $ScriptBlock, $ThrottleLimit = [Environment]::ProcessorCount)
{
	if ($PSVersionTable.PSVersion.Major -ge 7)
	{
		$InputObject | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit
	}
	else
	{
		$IsSerial = $True
		$InputObject | ForEach-Object -Process $ScriptBlock
	}
}

