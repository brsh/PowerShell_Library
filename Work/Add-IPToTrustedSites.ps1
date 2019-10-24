## Making it so windows can access a fileshare by IP 
[bool] $bDoIt = $true
[int] $UseThis = 1
[string] $IPToMakeSafe = '192.168.1.1'

$UsedNumbers = New-Object System.Collections.ArrayList

$CurLoc = Get-Location

#Path to the IP Range section of the Trusted Sites in the Registry
$keys = get-childitem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges"

#If there are any, check to see if the IP is already trusted
if ($keys.Count -gt 0) {
	$items = $keys | ForEach-Object { Get-ItemProperty $_.PSPath }

	foreach ($item in $items) {
		$null = $UsedNumbers.Add($Item.PSChildName.ToCharArray()[-1])
		[string] $range = $item.{:Range}
		if ($range = $IPToMakeSafe) {
			Write-Host 'Found IP! Not Gonna Do Nothing!'
			$bDoIt = $false
			break
		}
	}
	#The Range# entries are consecutive ... except when they're not
	#(like when you remove one, they don't renumber), so we'll figure
	#out the first available number and use that
	1..9999 | ForEach-Object { if ($_.ToString() -notin $UsedNumbers) { $UseThis = $_; break } }
} 

if ($bDoIt) {
	#Now let's try to do something...
	try {
		Write-Host 'Trying to add IP to Trusted Sites'
		Set-Location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges"
		New-Item "Range${UseThis}"
		Set-Location "Range${UseThis}"
		New-ItemProperty . -Name '*' -Value 2 -Type DWORD
		New-ItemProperty . -Name ':Range' -Value $IPToMakeSafe -Type STRING
		Write-Host 'Success'
	} catch {
		Write-Host "Error Adding Entries"
		Write-Host $_.Exception.Message
	}

	Set-Location $CurLoc
}