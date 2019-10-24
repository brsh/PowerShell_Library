$AllServices = New-Object System.Collections.ArrayList

[void] $AllServices.Add('bthserv')				# Bluetooth Support Service
[void] $AllServices.Add('CDPUserSvc')			# CDPUserSvc
[void] $AllServices.Add('dmwappushservice')		# dmwappushsvc
[void] $AllServices.Add('MapsBroker')			# Downloaded Maps Manager
[void] $AllServices.Add('lfsvc')				# Geolocation Service
[void] $AllServices.Add('SharedAccess')			# Internet Connection Sharing (ICS)
[void] $AllServices.Add('wlidsvc')				# Microsoft Account Sign-in Assistant
#[void] $AllServices.Add('NgcSvc')				# Microsoft Passport
#[void] $AllServices.Add('NgcCtnrSvc')			# Microsoft Passport Container
[void] $AllServices.Add('PhoneSvc')				# Phone Service
[void] $AllServices.Add('SensorDataService')	# Sensor Data Service
[void] $AllServices.Add('SensrSvc')				# Sensor Monitoring Service
[void] $AllServices.Add('SensorService')		# Sensor Service
[void] $AllServices.Add('WiaRpc')				# Still Image Acquisition Events
[void] $AllServices.Add('OneSyncSvc')			# Sync Host
[void] $AllServices.Add('TabletInputService')	# Touch Keyboard and Handwriting Panel Service
[void] $AllServices.Add('WalletService')		# WalletService
[void] $AllServices.Add('Audiosrv')				# Windows Audio
[void] $AllServices.Add('AudioEndpointBuilder')	# Windows Audio Endpoint Builder
[void] $AllServices.Add('FrameServer')			# Windows Camera Frame Server
[void] $AllServices.Add('stisvc')				# Windows Image Acquisition (WIA)
[void] $AllServices.Add('wisvc')				# Windows Insider Service
[void] $AllServices.Add('icssvc')				# Windows Mobile Hotspot Service
#[void] $AllServices.Add('WpnService')			# Windows Push Notifications System Service
#[void] $AllServices.Add('WpnUserService')		# Windows Push Notifications User Service
[void] $AllServices.Add('XblAuthManager')		# Xbox Live Auth Manager
[void] $AllServices.Add('XblGameSave')			# Xbox Live Game Save

ForEach ($service in $AllServices) {
	Write-Host "Disabling $service on localhost"
	Set-Service -Name $service -StartupType Disabled
}

Write-Host "Disabling Xbox tasks on localhost"
Get-ScheduledTask -TaskPath "\Microsoft\XblGameSave\" | Disable-ScheduledTask

Write-Host "Disabling CEIP Tasks"
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Disable-ScheduledTask

Write-Host "And only send security related telemetry [Enterprise] or basic [All other editions]"
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Value 0 -Force
