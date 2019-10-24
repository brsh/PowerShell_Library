<#
.SYNOPSIS
    Adds a new user to the 'local' machine
 
.DESCRIPTION
    A basic quasi-replica of the *nix useradd command. A simple way to bulk add new users to the 'local' system. 
    I say local: this is not for Active Directory. I've tried to match some of the parameters (as appropriate) from 
    the linux world, but some don't make sense. Also, more verbose PowerShell parameters are (of course) available.

    Options:
      -b, -base-dir BASE_DIR       base directory for the home directory of the new account
      -c, -comment COMMENT         Description field of the new account
      -d, -home-dir HOME_DIR       home directory of the new account
      -e, expiredate DATE          date the new account will expire
      -G, -groups GROUPS           list of supplementary groups of the new account
      -h, -help                    display this help message and exit
      -k, -skel SKEL_DIR           use this alternative skeleton dire
      -p, -password PASSWORD       encrypted password of the new account
      -t, -CannotChange             user cannot change password
      -m, -MustChange               user must change password at next logon
      -a, -Disabled                 create but do not enable the account

.PARAMETER Name
    Parameter Description

.EXAMPLE
     Add-LocalUser.ps1 -Parameter

#>


[CmdletBinding()]
param (
    [Parameter(Position=0,Mandatory=$True,
    HelpMessage="What is the username?",
    ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullorEmpty()]
    [Alias("user","u","sAMAccountName")]
    [string]$UserName, 
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [Alias("computername","machine","vm")]
    [string[]] $Computer = $env:COMPUTERNAME, 
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [Alias("pwd","p", "passwd")]
    [string] $Password = $($null = [Reflection.Assembly]::LoadWithPartialName("System.Web"); [System.Web.Security.Membership]::GeneratePassword(15,2))


)

BEGIN { 
    # [Alias("a")]
    # [switch] $Disabled = $false,
    # [Alias("m")]
    # [switch] $MustChange = $false,
    # [Alias("t")]
    # [switch] $CannotChange = $false,
    # [Alias("e")]
    # [datetime] $ExpireDate = get-date,
    # [switch] $Passthru = $false

    function Bind-ToLocalMachine {
        param(
            [string] $computer = "."
        )
        write-verbose "Connecting to $computer"
        [adsi] $adsiComputer = "WinNT://$computer"
        write-verbose "Found: $adsiComputer.Path"
        return $adsiComputer
    }

    function New-User {
        param (
            [adsi] $adsiComputer,
            [string] $UserName = "",
            [string] $Password = "",
            
            [string] $FullName = ""
        )

        $newuser = $adsiComputer.Create("User", $UserName)
        $newuser.SetPassword($Password)
    }

    function Set-Description {
        param (
            [string] $Description = ""
        )
    }
}

PROCESS { 
    # of course, Powershell 5.1 makes this easy...
    # if (($PSVersionTable.PSVersion.Major -gt 5) -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -ge 1)) {
    #     "We good"
    # }
    # else {


    # }
    $adsiComputer = Bind-ToLocalMachine
    New-User -adsiComputer $adsiComputer -UserName $UserName -Password $Password

}

END { }

