
# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

#Pull Currently Loaded user hives (users who are logged in)
$LoadedHives = Get-ChildItem registry::Hkey_Users | Where-Object { $_.PSChildName -match $PatternSID } | Select-Object PSChildName

# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } |
ForEach-Object {
	[bool] $IsLoaded = $false
	if ($LoadedHives.PSChildName -contains $_.PSChildName) {
		$IsLoaded = $true
	}

	[PSCustomObject] @{
		SID        = $_.PSChildName
		UserHive   = "$($_.ProfileImagePath)\ntuser.dat"
		UserName   = $_.ProfileImagePath -replace '^(.*[\\\/])', ''
		IsLoggedIn = $IsLoaded
	}
}

# Add in the .DEFAULT User Profile
$DefaultProfile = "" | Select-Object SID, UserHive, UserName, IsLoggedIn
$DefaultProfile.SID = ".DEFAULT"
$DefaultProfile.Userhive = "C:\Users\Public\NTuser.dat"
$DefaultProfile.UserName = "Default"
$DefaultProfile.IsLoggedIn = $true
$ProfileList += $DefaultProfile

$ProfileList | ForEach-Object {

	# Load User ntuser.dat if it's not already loaded
	IF (-not $_.IsLoggedIn) {
		$null = reg load HKU\$($_.SID) $($_.UserHive)
	}

	#Here we're just checking the screensaver settings, but you can do a bunch of stuff
	try {
		$ScreenSaveActive = Get-ItemPropertyValue "Registry::HKEY_USERS\$($_.SID)\Control Panel\Desktop" -Name 'ScreenSaveActive' -ErrorAction Stop
	} catch { $ScreenSaveActive = 'N/A' }
	try {
		$ScreenSaverIsSecure = Get-ItemPropertyValue "Registry::HKEY_USERS\$($_.SID)\Control Panel\Desktop" -Name 'ScreenSaverIsSecure' -ErrorAction Stop
	} catch { $ScreenSaverIsSecure = 'N/A' }
	[pscustomobject] @{
		User                = $_.UserName
		ScreenSaveActive    = $ScreenSaveActive
		ScreenSaverIsSecure = $ScreenSaverIsSecure
	}

	# Unload ntuser.dat
	if (-not $_.IsLoggedIn) {
		### Garbage collection and closing of ntuser.dat ###
		[gc]::Collect()
		$null = reg unload HKU\$($_.SID)
	}

}
