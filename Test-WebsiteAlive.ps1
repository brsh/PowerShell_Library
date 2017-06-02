<#
.SYNOPSIS
    Tests for valid HTML response from a Website

.DESCRIPTION
    Tests a website for response. Enter a url, and the script will test for a 'valid' response.
    By default, valid is merely ... it responds ok (HTML 200). Very slim definition. You can,
    however, qualify the expected response (via the -ExpectedResponse parameter) so it must find
    specific text (or texts via a string array) or, via the -InvertMatch parameter it must NOT find
    specific text. There's also an -All switch to force matching (or not) ALL ExpectedText entries.

    Alternatively, you can specify that it must return specific HTML return codes (via the
    -ResponseCode parameter with, yep, a string array).

    It will return an object with True or False for alive (based on any Expected qualifiers) as
    well as the response code and text (if it can) or the encountered error (if it can't get the code)

.INPUTS
    Supports pipeline, so you can pass it any of the parameters, as long as you specify the name

.OUTPUTS
    Returns an object that lists:
        True or False if the site is alive (qualified by any Expected Texts or Codes)
        The HTML Reponse Code (if it can get it)
        The HTML Response Code Meaning (if it can get it)

    Plus (not in the default list of properties):
        The Error Message (if the process failed)
        The Full Captured Text returned by the site (if any and if possible)

.PARAMETER WebSite
    The URL (URI, IRI, address...) to check. Returns boolean true for up, false for down

.PARAMETER ExpectedText
    The text you want to have somwhere in the reponse (or nowhere in the response if -InvertMatch is used)

.PARAMETER ExpectedCode
    The response code expected from the site (200 = ok; 404 = not found, etc.) (or not expected if -InvertMatch is used)

.PARAMETER MustMatchAll
    Must match all ExpectedText entries (only useful if you specify more than 1 ExpectedText items)

.PARAMETER InvertMatch
    Inverts the meaning of ExpectedText and ExpectedCode - means the text must NOT exist in the response

.EXAMPLE
    Test-WebsiteAlive.ps1 -WebSite www.microsoft.com

    Probably returns True with a 200 code

.EXAMPLE
    Test-WebsiteAlive.ps1 -WebSite www.microsoft.com -ExpectedText 'Use Bing'

    Probably returns True with a 200 code (MS is likely to suggest this)

.EXAMPLE
    Test-WebsiteAlive.ps1 -WebSite www.microsoft.com -ExpectedText 'Use Google' -InvertMatch

    Probably returns True with a 200 code (MS would never suggest this)

.EXAMPLE
    Test-WebsiteAlive.ps1 -WebSite www.microsoft.com -ExpectedText 'Use Bing', 'Use Google'

    Probably returns True with a 200 code (cuz they will suggest using Bing, so it matches)

.EXAMPLE
    Test-WebsiteAlive.ps1 -WebSite www.microsoft.com -ExpectedText 'Use Bing', 'Use Google' -All

    Probably returns False with a 200 code (cuz they won't suggest using both)

.EXAMPLE
     Test-WebsiteAlive.ps1 -WebSite www.microsoft.com -ExpectedCode '200'

     Probably returns True (cuz their site will likely be Ok)

.EXAMPLE
     Test-WebsiteAlive.ps1 -WebSite www.microsoft.com -ExpectedCode '200', '500'

     Probably returns true (the site will probably return 200; but also could have a server error)

.EXAMPLE
     Test-WebsiteAlive.ps1 -WebSite www.microsoft.com/AllBillsSecrets -ExpectedCode '200', '201'

     Probably returns false with a 401 (unless you're authorized)

#>


[CmdletBinding(DefaultParameterSetName="Text")]
param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Text',Position=0)]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Code',Position=0)]
    [ValidateNotNullOrEmpty()]
    [Alias('Site', 'Name', 'URL', 'Address', 'Location', 'IRI')]
    [string[]] $WebSite,
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Text')]
    [Alias('Snippet', 'Text', 'Find')]
    [string[]] $ExpectedText = $null,
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Text')]
    [Alias('All')]
    [switch] $MustMatchAll = $false,
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Code')]
    [Alias('Returns', 'Code')]
    [string[]] $ExpectedCode = $null,
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Text')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Code')]
    [Alias('NotMatch', 'NoMatch', 'IsNot')]
    [switch] $InvertMatch = $false
)
# ExpectedResponse
Begin {
    $WebClient = New-Object System.Net.WebClient

    Function Test-Match {
        param (
            [string] $ToTest = ""
        )
        [bool] $retval = $false
        [int16] $TotalFound = 0
        if ($PSCmdlet.ParameterSetName -eq "Text") {
            $ToTestAgainst = $ExpectedText
        } else {
            $ToTestAgainst = $ExpectedCode
        }
        [int16] $TotalSeeking = $ToTestAgainst.Count
        Write-Verbose "TotalSeeking Begin: $TotalSeeking"
        Write-Verbose "TotalFound Begin: $TotalFound"
        if ($ToTest -eq "") {
            Write-Verbose "Nothing to test against..."
            $retval = $false
        } else {
            $ToTestAgainst | ForEach-Object {
                Write-Verbose "Checking for: '$_'"
                if ($InvertMatch) {
                    if ($ToTest -notmatch $_) {
                        $TotalFound += 1
                    }
                } else {
                    if ($ToTest -match $_) {
                        if ($MustMatchAll) {
                            Write-Verbose "Found (must match all): $_"
                            $TotalFound += 1
                        } else {
                            $TotalFound = $TotalSeeking
                            Write-Verbose "Found (must match one): $_"
                        }
                    } else {
                        Write-Verbose "Not found: $_"
                    }
                }
            }
        }
        if ($TotalFound -ge $TotalSeeking) { write-verbose "True Dat"; $retval = $true } else { write-verbose "False Dat"; $retval = $false }
        Write-Verbose "TotalSeeking End: $TotalSeeking"
        Write-Verbose "TotalFound End: $TotalFound"
        Write-Verbose "Returning $retval"
        $retval
    }
    Function ParseError {
        param (
            [string] $Message = ""
        )
        [string] $Code = ""
        [string] $Response = ""

        switch ($Message) {
            {$_ -match 'calling DownloadString' }   { [string] $Temp = ($Message.Split(':')[-1]).Trim()
                                                        $Code = [string] $Temp -replace '\D+'
                                                        $Response = $Temp.Split(')')[1].Trim().TrimEnd('.')
                                                        write-verbose $Temp
                                                    }
            default                                 { $Code = '999'; $Response = $_ }
        }

        Return $Code, $Response

    }
}

Process {
    foreach ($Site in $WebSite) {
        if (($Site -notmatch '^http[s]')) { $Site = "http://${Site}"}
        [bool] $flag = $false
        [string] $ResponseCode = "0"
        [string] $Response = "Unknown"
        $ReturnedText = $null
        [string] $ErrorMessage = "No Error"
        $out = New-Object psobject
        #if ($PSCmdlet.ParameterSetName -eq 'Text') {
            Try {
                $ReturnedText = $WebClient.DownloadString($Site)
                $flag = $true
                $ResponseCode = "200"
                $Response = "Ok"
                if (($PSCmdlet.ParameterSetName -eq 'Text') -and ($ExpectedText)) {
                    $flag = Test-Match -ToTest $ReturnedText
                    Write-Verbose "flag is: $flag"
                }
            } Catch {
                # Something went wrong...
                $ErrorMessage = [string] ($_.Exception.Message).Replace('"', '')
                Write-Verbose $ErrorMessage
                $ResponseCode, $Response = ParseError -Message $ErrorMessage
                $flag = $false
            }
        #}

        if (($PSCmdlet.ParameterSetName -eq 'Code') -and ($ExpectedCode)) {
            $flag = Test-Match -ToTest $ResponseCode
            Write-Verbose "flag is: $flag"
        }

        Add-Member -InputObject $out -MemberType NoteProperty -Name "Alive" -Value $flag
        Add-Member -InputObject $out -MemberType NoteProperty -Name "ResponseCode" -Value $ResponseCode
        Add-Member -InputObject $out -MemberType NoteProperty -Name "ResponseText" -Value $Response
        Add-Member -InputObject $out -MemberType NoteProperty -Name "FullError" -Value $ErrorMessage
        Add-Member -InputObject $out -MemberType NoteProperty -Name "CapturedText" -Value $ReturnedText

        #Sets the "default properties" when outputting the variable... but really for setting the order
        $defaultProperties = @('Alive', 'ResponseCode', 'ResponseText')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        Add-Member MemberSet PSStandardMembers $PSStandardMembers -InputObject $out

        $out
    }
}
End { }



# function loginIE
# {
# $ie = New-Object -com "InternetExplorer.Application"
# $ie.Navigate("http://www.mysite.com")
# $ie.visible = $true

# do { sleep 5 }
# while ( $ie.busy )

# $doc = $ie.document
# $user = $doc.getElementById("Login")
# $password = $doc.getElementById("Password")
# $submit = $doc.getElementById("Submit")

# $user.value = "yourUserName"
# $password.value = "yourPassword"
# $submit.Click();

# $ie.Quit();
# }


