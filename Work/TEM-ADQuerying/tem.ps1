
<#
.SYNOPSIS
    Creates the Telephone Expense CSV list

.DESCRIPTION
    Queries AD for all (applicable) users, and outputs the data into the tem.csv file. Accpunts must meet the following criteria:
        Must be a user
        Must be an "organizational person"
        Must have an employe ID
        Must have a given name
        Must have something in the extensionAttribute5 field
        Must NOT have Admin at the end of the account name

    This script pulls all of the records, sorts them, and saves them to the csv file for upload to our TEM processing company.

.PARAMETER DisplayOnly
    For troubleshooting purposes, displays the results rather than writing them to the file

.EXAMPLE
    PS C:\> Get-TemUserList

    
#>



param ( 
    [Parameter(Position=0,Mandatory=$False)] 
    [switch] $DisplayOnly = $false
)



Function Get-Users {
    #This is the Filter so we only pull the right info from AD
    #Only return: User and orgperson, with something in the EmpID, GivenName, and ExtenisonAtt5 fields
    #But exclue any account that ends in Admin
    $sFilter = "(&(objectClass=User)(objectcategory=organizationalperson)(employeeID=*)(givenname=*)(extensionAttribute5=*)(!(sAMAccountName=*admin)))"
    
    #This is the domain object
    $oDomain = New-Object System.DirectoryServices.DirectoryEntry
    
    #create the searcher object with these obvious properties
    $oSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $oSearcher.SearchRoot = $oDomain
    $oSearcher.PageSize = 1000
    $oSearcher.Filter = $sFilter
    $oSearcher.SearchScope = "Subtree"
    
    #We're only going to pull the following attributes
    $cProps = "samAccountName", "sn", "givenName", "mail", "extensionAttribute5", "userAccountControl", "extensionAttribute2"
    
    foreach ($i in $cProps) {
        $null = $oSearcher.PropertiesToLoad.Add($i)
    }
    
    #Now, pull them all in
    $cResults = $oSearcher.FindAll()
    
    #And cycle through them
    foreach ($oResult in $cResults) {
        #usrAccountControl holds the 'enabled'/'disabled' status of an account
        #we bitwise and it against 2 to see which...
        switch ($oResult.Properties.Item("userAccountControl")[0] -band 2) {
            0 { $uac = "A" }
            2 { $uac = "I" }
            default { $uac = "I" }
        }
    
        #Sometimes the hire date is empty, this just covers that possibility
        try {
            $hire = [datetime] $oResult.Properties.Item("extensionAttribute2")[0]
        }
        catch {
            $hire = [datetime] "01-01-1900"
        }
    
        #Most of these attributes are left-/held-over from the old version
        #I've left them in because I don't know which...
        $InfoHash =  @{
            samAccountName = $oResult.Properties.Item("samAccountName")[0]
            A1 = ""
            #name = $oResult.Properties.Item("Name")[0]
            sn = $oResult.Properties.Item("sn")[0]
            givenName = $oResult.Properties.Item("givenName")[0]
            mail = $oResult.Properties.Item("mail")[0]
            A3 = " "
            extensionAttribute5 = $oResult.Properties.Item("extensionAttribute5")[0]
            A4 = "Y"
            status = $uac
            A5 = " "
            A6 = " "
            A7 = " "
            hiredate = $hire.ToString("yyyy-MM-dd")
            A8 = " "
            A9 = " "
            A10 = " "
            A11 = " "
            A12 = " "
            A13 = " "
            A14 = " "
            A15 = " "
            A16	= "N"
            A17	= "N"
            A18	= "N"
            A19 = " "
            A20 = " "
            A21 = " "
            A22 = " "
            A23 = " "	
            A24 = " "
            A25 = "0"
        }
        
        #Create a new object for this info
        $InfoStack = New-Object -TypeName PSObject -Property $InfoHash
    
        #Add a (hopefully) unique object type name
        $InfoStack.PSTypeNames.Insert(0,"TEM.Users")

        #And output the object
        $InfoStack
    }
}




if ($DisplayOnly) {
    Get-Users | 
        select samAccountName, A1, sn, givenName, mail, A3, extensionAttribute5, A4, status, A5, A6, A7, Hiredate, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25 | 
        sort samaccountName | 
        ConvertTo-Csv | 
        % {$_ -replace '"',''} |
        select -skip 2 
}
else {
    Get-Users | 
        select samAccountName, A1, sn, givenName, mail, A3, extensionAttribute5, A4, status, A5, A6, A7, Hiredate, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25 | 
        sort samaccountName | 
        ConvertTo-Csv | 
        % {$_ -replace '"',''} |
        select -skip 2 | 
        Out-File TEM.csv
}

