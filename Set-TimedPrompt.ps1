Function Set-TimedPrompt {
	<#
.SYNOPSIS
A choice prompt with a timeout

.DESCRIPTION
A 'simple' way to create a prompt that will timeout and automatically select a default.
You can provide a prompt, the possible options (or answers), and a timeout value. This
function will try to select a single keystroke to choose the various options, or use a
number if that letter is not available. You can also provide your own key by putting
an ampersand ('&') before your letter.

The counter will change from green to yellow to red depending how much time is left.

The function returns an object that contains:
	Response : The original text of the option (ampersand included if present)
	NoAmp    : The original text with any ampersand removed
	ActionKey: The key to select

The ToString() method of the object will return the Response text


.PARAMETER Prompt
The text to prompt or question for the user

.PARAMETER SecondsToWait
How long the script will wait before selecting the default

.PARAMETER Options
A string array of options to choose from. The first option will be the default. Use an
ampersand to hard set a keystroke to select, otherwise, the first character will be used
(or a number if the character is already taken). Eg. "Heck &Yes" = Y; "Heck No" = H

.EXAMPLE
Set-TimedPrompt -Prompt "Which Way?" -Options "Up", "Down" -SecondsToWait 60
Which Way?

 U : Up
 D : Down

Default is 'Up' in 58


Response
--------
Up

.EXAMPLE
Set-TimedPrompt -Prompt "Which Way?" -Options "U&p", "Down", "Don't Know" -SecondsToWait 60
Which Way?

 P : Up
 D : Down
 1 : Don't Know

Default is 'Up' in 53


Response
--------
Down

.EXAMPLE
$a = Set-TimedPrompt -Prompt "Which Way?" -Options "Up", "Down", "D&on't Know" -SecondsToWait 60
Which Way?

 U : Up
 D : Down
 O : Don't Know

Default is 'Up' in 58

PS C:\> $a.Tostring()
D&on't Know

#>
	param (
		[Parameter(Mandatory = $false)]
		[Alias('Question')]
		[string] $Prompt = "Please confirm you want to continue",
		[Parameter(Mandatory = $false)]
		[Alias('Timer', 'HowLong', 'Wait')]
		[int] $SecondsToWait = 10,
		[Parameter(Mandatory = $false)]
		[Alias('Answers')]
		[string[]] $Options = @("&Yes", "&No")
	)

	[int] $i = $SecondsToWait
	[bool] $keepgoing = $true
	[bool] $TimedOut = $false
	[string] $Alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	[string] $Numa = "123456789"
	[string] $AllowedKeys = ""
	[string] $Color = 'Green'

	$OptionsArray = @()
	$Options | ForEach-Object {
		if ($_.Contains('&')) {
			[string] $initial = $_.Substring($_.IndexOf('&') + 1, 1 ).ToUpper()
		} else {
			[string] $initial = $_.ToString().Substring(0, 1).ToUpper().ToUpper()
		}

		if ($Alpha.Contains($initial)) {
			$alpha = $alpha.Replace($initial, "")
		} else {
			$initial = $Numa.Substring(0, 1)
			$Numa = $Numa.Substring(1)
		}
		$AllowedKeys += $initial
		$OpHash = @{
			Response  = $_
			NoAmp     = $_.Replace('&', '')
			ActionKey = $initial
		}

		$OpObject = New-Object -TypeName PSObject -Property $OpHash

		$OpObject = $OpObject | Add-Member -MemberType ScriptMethod -Name ToString -Value { "{0}" -f $this.Response.PsBase.ToString() } -force -PassThru

		$defaultProperties = @('Response')
		$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultProperties)
		$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
		$OpObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers

		$OptionsArray += $OpObject

	}

	$AllowedKeys = $AllowedKeys.ToUpper() + $AllowedKeys.ToLower()

	Write-Host $Prompt -ForegroundColor Yellow
	Write-Host ""
	$OptionsArray | ForEach-Object { Write-Host " $($_.ActionKey) : $($_.NoAmp)" }
	Write-Host ""

	$CursorPosition = $Host.UI.RawUI.CursorPosition

	while ($keepgoing) {
		if ([console]::KeyAvailable) {
			# Any key will quit
			$x = [System.Console]::ReadKey($true)

			switch ($AllowedKeys) {

				{ $_.Contains($x.Key) } { $retval = $OptionsArray | Where-Object { $_.ActionKey -eq $x.Key }; $keepgoing = $false; $TimedOut = $false; break }
				DEFAULT { $keepgoing = $true}
			}
		} else {
			Switch ($i) {
				{ $i -eq 0 } {$Color = 'Red'; break}
				{ [math]::floor(($SecondsToWait / $i)) -gt [math]::floor($SecondsToWait * ( 1 / 3)) } { $Color = 'Red'; break }
				{ [math]::floor(($SecondsToWait / $i)) -gt [math]::floor($SecondsToWait * (1 / 6)) } { $Color = 'Yellow'; break }
				DEFAULT { $Color = 'Green'; break}
			}
			$Host.UI.RawUI.CursorPosition = $CursorPosition
			Write-Host "Default is '$($OptionsArray[0].NoAmp)' in " -NoNewline
			Write-Host $i.ToString().PadRight($SecondsToWait.ToString().Length) -NoNewline -ForegroundColor $Color
			Write-Host ""
			Start-Sleep -Milliseconds 1000
			if ($i -eq 0) { $retval = $OptionsArray[0]; $keepgoing = $false; $TimedOut = $true}

			$i -= 1
		}
	}
	$retval

}
