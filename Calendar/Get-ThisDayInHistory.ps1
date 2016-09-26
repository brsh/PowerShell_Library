<#
    .SYNOPSIS 
        Gets Today In History from misc. Calendar files
         
    .DESCRIPTION 
        This script is a (slight) porting of the unix Calendar command (using the same text data files/format). It parses the data subfolder for calendar.* files, displaying lines that begin with "today's" date (today can be changed on the command line - if only life were like that). The script allows info from 0-10 days before and after today as well. By default, the output is a standard powershell object for further parsing. However, using the -FormatIt parameter, it will output sorted text wrapped to screen width (sort date, event | format-table -wrap -autosize). You can also specify the year for some of the "changeable" events (like Easter or Leap Day).
 
    .PARAMETER  FormatIt
        Switch sorting and word-wrap on
 
    .PARAMETER  Today
        Specify what day you'd like listed - can be in any valid datetime format (like 09/23 or "March 23")

    .PARAMETER  Before
        An integer from 0 to 10 specifying how many days before Today to list

    .PARAMETER  After
        An integer from 0 to 10 specifying how many days after Today to list

    .PARAMETER  Year
        4-digit number specifying a different year

    .EXAMPLE 
        PS C:\> .\Get-ThisDayinHistory.ps1

        Date  Event
        ----  -----
        04/07 IBM announces System/360, 1964
        04/07 Albert Hofmann synthesizes LSD in Switzerland, 1943
        04/07 Alewives run, Cape Cod
         
    .EXAMPLE 
        PS C:\> .\Get-ThisDayinHistory.ps1 -formatit

        Date  Event
        ----  -----
        04/07 Albert Hofmann synthesizes LSD in Switzerland, 1943
        04/07 Alewives run, Cape Cod
        04/07 IBM announces System/360, 1964
     
    .EXAMPLE 
        PS C:\> .\Get-ThisDayinHistory.ps1 -today "April 7" -Before 2 -After 1 -FormatIt

        Date  Event
        ----  -----
        04/05 Thomas Hobbes born, 1588, philosopher
        04/06 Joseph Smith founds Mormon Church, 1830
        04/07 Albert Hofmann synthesizes LSD in Switzerland, 1943
        04/07 Alewives run, Cape Cod
        04/07 IBM announces System/360, 1964
        04/08 Buddha born, 563 BC
        04/08 David Rittenhouse born, 1732, astronomer & mathematician
        04/08 Matthew Flinders and Nicolas Baudin meet in Encounter Bay, 1802
 
    .EXAMPLE 
        PS C:\> .\Get-ThisDayinHistory.ps1 -today 04/07 -Year 2015 -Before 2 -After 1 -FormatIt

        Date  Event
        ----  -----
        04/05 Easter Sunday (the day of the highest church attendance)
        04/05 Thomas Hobbes born, 1588, philosopher
        04/06 Joseph Smith founds Mormon Church, 1830
        04/07 Albert Hofmann synthesizes LSD in Switzerland, 1943
        04/07 Alewives run, Cape Cod
        04/07 IBM announces System/360, 1964
        04/08 Buddha born, 563 BC
        04/08 David Rittenhouse born, 1732, astronomer & mathematician
        04/08 Matthew Flinders and Nicolas Baudin meet in Encounter Bay, 1802


#>

[CmdletBinding()]

param (
    [parameter(Mandatory=$false)]
    [alias("A")]
    [ValidateRange(0,10)]
    [int] $After = 0,
    [parameter(Mandatory=$false)]
    [alias("B")]
    [ValidateRange(0,10)]
    [int] $Before = 0,
    [datetime] $Today = (get-date),
    [parameter(Mandatory=$false, HelpMessage="Enter a valid 4-digit year")]
    [ValidateScript( {
        if ($_ -match "[0-9][0-9][0-9][0-9]") { $true }
        else { throw "$_ is not a valid 4-digit year" }
    })]
    [int] $Year = (get-date).tostring("yyyy"),
    [parameter(Mandatory=$false)]
    [switch] $FormatIt = $false,
    [parameter(Mandatory=$false)]
    [switch] $All = $false
)

function Get-Easter {
    # See http://poshcode.org/3527
    $a = $Year % 19
    $b = [Math]::Floor($Year / 100)
    $c = $Year % 100
    $d = [Math]::Floor($b / 4)
    $e = $b % 4
    $f = [Math]::Floor(($b + 8) / 25)
    $g = [Math]::Floor((($b - $f + 1) / 3))
    $h = ((19 * $a) + $b + (-$d) + (-$g) + 15) % 30
    $i = [Math]::Floor($c / 4)
    $k = $c % 4
    $L1 = -($h + $k) #here because powershell is picking up - (subtraction operator) as incorrect token
    $L = (32 + (2 * $e) + (2 * $i) + $L1) % 7
    $m = [Math]::Floor(($a + (11 * $h) + (22 * $L)) / 451)
    $v1 = -(7 * $m) #here because powershell is picking up - (subtraction operator) as incorrect token
    $month = [Math]::Floor(($h + $L + $v1 + 114) / 31)
    $day = (($h + $L + $v1 + 114) % 31) + 1

    [System.DateTime]$date = "$Year/$month/$day"
    $date
}

function Get-Info {
    [string] $include = 'calendar.*'
    [string] $date = (get-date).ToString("MM/dd")

    $retval = (Get-ChildItem -Recurse -Path $ScriptPath\data -Include $include | select-string -Pattern "^[a-zA-Z0-9]").Line
    $retval | ForEach-Object {
        if ($_ -ne $null) {
            [string] $workdate, [string] $text = ($_).ToString().Trim() -Split "\t"
            switch -Regex ($workdate) {
                "\d\d/\d\d"  { 
                        # Basic numbers in nn/nn format
                        $date = "$workdate"
                        break
                    }

                "\d\d/\D+"   { 
                        # mix of numbers and words in nn\Text format
                        # Text should be First, Second, etc.

                        [datetime] $SearchMonth = $workdate.Substring(0, 2) + '/1/' + $Year
                        
                        [string] $SearchDay = $workdate.Substring(3, 3)
                        switch ($workdate.Substring(6)) {
                            "First"  { $SearchNumber = 1; break }
                            "Second"  { $SearchNumber = 2; break }
                            "Third"  { $SearchNumber = 3; break }
                            "Fourth"  { $SearchNumber = 4; break }
                            "Fifth"  { $SearchNumber = 5; break }
                            "Last"   { $SearchNumber = -1; break }
                            Default { $SearchNumber = 1; break }
                        }

                        if ($SearchNumber -ge 0) {
                            while ($SearchMonth.DayofWeek -notmatch $SearchDay ) { $SearchMonth=$SearchMonth.AddDays(1) }
                            $SearchMonth = $SearchMonth.AddDays(7*($SearchNumber-1))
                        } else {
                            $SearchMonth = $SearchMonth.AddMonths(1).AddDays(-1)
                            while ($SearchMonth.DayofWeek -notmatch $SearchDay ) { $SearchMonth=$SearchMonth.AddDays(-1) }
                        }

                        $date = $SearchMonth.ToString("MM/dd")
                        break
                    }

                "\D+"        { 
                        #Words - at the moment, this is only easter
                        [datetime] $Easter = Get-Easter
                        [int] $Modifier = $workdate.Substring(6)
                        $Easter = $Easter.AddDays($Modifier)
                        $date = $Easter.ToString("MM/dd")
                        break
                    }

                default      {
                        #Dunno what this is 
                        $date = (get-date).ToString("MM/dd")
                        break
                    }

            }

            if ($text.Length -gt 0) {
                [bool] $DoIt = $false
                if ($all) {
                    $DoIt = $true
                }
                else {
                    if (( $Date -ge $BeforeDate.ToString("MM/dd") ) -and ( $Date -le $AfterDate.ToString("MM/dd"))) {
                        $Doit = $true
                    } 
                    else {
                        $DoIt = $false
                    }
                }
                
                if ($DoIt) {
                    $InfoHash =  @{
                        Date = $Date
                        Event = $Text
                        OriginalDate = $workdate
                    }
                    $InfoStack = New-Object -TypeName PSObject -Property $InfoHash

                    #Add a (hopefully) unique object type name
                    $InfoStack.PSTypeNames.Insert(0,"ThisDatInHistory.Information")

                    #Sets the "default properties" when outputting the variable... but really for setting the order
                    $defaultProperties = @('Date', 'Event')
                    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
                    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
                    $InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                    if ($FormatIt) {
                        $Script:AllResults += $InfoStack
                    }
                    else {
                        $InfoStack
                    }
                }
            }

        }

    }
}


# Current script path
[string] $ScriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent

$Script:AllResults = @()

[DateTime] $BeforeDate = $Today.AddDays(0 - $Before)
[DateTime] $AfterDate = $Today.AddDays($After)

Get-Info 

if ($FormatIt) {
    $AllResults | Sort-Object Date, Event | ft Date, Event -AutoSize -Wrap
}