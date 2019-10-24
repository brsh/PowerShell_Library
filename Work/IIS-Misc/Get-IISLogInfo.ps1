# Pull IIS info
Function Get-IISLogInfo {
    Import-Module WebAdministration
    $a = Get-ChildItem iis:\sites | select -Property Name,ID,State,Bindings -ExpandProperty Logfile 

    $a | foreach-object {
        try {
                $path = "$($_.Directory)\W3SVC$($_.ID)"
                [datetime] $log = (get-childitem -path $path -erroraction Stop | sort-object LastWriteTime -Descending | select-object -First 1).LastWriteTime
            } catch {
                [string] $log = ''
            }
        [string[]] $prots = @()
        $_.Bindings.Collection | foreach-object {
            if (($_.Protocol -match 'http') -or ($_.Protocol -match 'ftp')) {
               $prots += $_.Protocol
            }
        }
        $hash = @{
            Name = $_.Name
            ID = $_.ID
            State = $_.State
            LogDirectory = $path
            MostRecentLog = $log
            Protocol = $prots -join ','
        }
        New-Object -typename PSObject -Property $Hash
    } | Select Name, ID, State, Protocol, LogDirectory, MostRecentLog 
}

Get-IISLogInfo | Format-Table -Autosize

