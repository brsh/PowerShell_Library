function Get-PowerShellTelemetryReporting {
	<#
	.SYNOPSIS
	Enables/Disables PowerShell Telemetry Reporting

	.DESCRIPTION
	PowerShell 7 adds telemetry reporting to Microsoft. In some cases, that's a good thing.
	In others, not so much. You decide.

	This function will check if THIS instance of PowerShell has telemetry enabled. It's a
	global ENV var, but it must exist BEFORE pwsh is instantiated.

	.EXAMPLE
	Get-PowerShellTelemetryReporting

	Shows whether telemetry reporting is enabled

	.LINK
	https://devblogs.microsoft.com/powershell/new-telemetry-in-powershell-7-preview-3/
	#>

	param (
		[switch] $Simple = $false
	)

	if ($PSVersionTable.PSVersion.Major -ge 7) {
		[string] $setting = $env:POWERSHELL_TELEMETRY_OPTOUT
		[bool] $IsEnabled = $true
		if (-not $Simple) {
			Write-Host "Powershell Telemetry Reporting is controlled via ENV:\POWERSHELL_TELEMETRY_OPTOUT"
			Write-Host "  To disable, it must be 'true', 'yes', or '1'"
		}
		if (($setting.Length -le 0) -or ($null = $setting)) {
			$IsEnabled = $true
		} elseif (($setting.ToLower() -eq 'true') -or ($setting.ToLower() -eq 'yes') -or ($setting -eq '1')) {
			$IsEnabled = $false
		} else {
			if (-not $Simple) { Write-Host "  Current setting is: $setting" -ForegroundColor Yellow }
		}
		if (-not $Simple) {
			if ($IsEnabled) {
				Write-Host "  Telemetry reporting is ENABLED" -ForegroundColor Red
			} else {
				Write-Host "  Telemetry reporting is DISABLED" -ForegroundColor Green
			}
		}
	} else {
		if (-not $Simple) { Write-Host 'Only PowerShell version 7 and above have the telemetry reporting option. Reporting is NOT enabled.' -ForegroundColor Green }
		$IsEnabled = $false
	}
	if ($Simple) { $IsEnabled }
}

function Set-PowerShellTelemetryReporting {
	<#
	.SYNOPSIS
	Enables/Disables PowerShell Telemetry Reporting

	.DESCRIPTION
	PowerShell 7 adds telemetry reporting to Microsoft. In some cases, that's a good thing.
	In others, not so much. You decide.

	You must be an admin to modify "global" environment variables... and you have to set it
	globally because it must exist BEFORE pwsh is instantiated.

	.EXAMPLE
	Set-PowerShellTelemetryReporting

	Tries to disable Telemetry Reporting

	.EXAMPLE
	Set-PowerShellTelemetryReporting -Enable

	Tries to enable Telemetry Reporting

	.LINK
	https://devblogs.microsoft.com/powershell/new-telemetry-in-powershell-7-preview-3/
	#>
	param (
		$Enable = $false
	)
	if ($PSVersionTable.PSVersion.Major -ge 7) {
		Write-Host "Powershell Telemetry Reporting is controlled via ENV:\POWERSHELL_TELEMETRY_OPTOUT"
		Write-Host "  To disable, it must be 'true', 'yes', or '1'"

		try {
			if ($Enable) {
				if (Get-PowerShellTelemetryReporting -Simple) { [Environment]::SetEnvironmentVariable("MyTestVariable", $null, "Machine") }
			} else {
				[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', 'Machine')
			}
		} catch {
			Write-Host 'Error setting environment variable' -ForegroundColor Red
			Write-Host 'You prolly need to run this as Admin' -ForegroundColor Yellow
			Write-Host $_.Exception.Message
		}
	}
} else {
	Write-Host 'Only PowerShell version 7 and above have the telemetry reporting option. Reporting is not an option.' -ForegroundColor Green
}
}
