Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Snapin # Import Exchange Powershell
Set-ADServerSettings -ViewEntireForest $true # Allow commands to see users in subdomains
$path = 'c:\path\to\logdirectory' #establish path to log file
$date = Get-Date -Format 'yyyy-MM-dd' #establish date to be used in log file
$logFile = Join-Path -Path $path -ChildPath "$date-log.txt" #establish the path for log file
$forest = (Get-ADForest).domains #get list of domains to be used in the foreach on line 25

# Set Nipr or SIPR
$Enclave = Get-ADDomain | select distinguishedname
if (($Enclave.DistinguishedName) -eq "DC=domain,DC=NAVY,DC-SMIL,DC=MIL"){
    $OU = "DC=NAVY,DC=SMIL,DC=MIL"
}
if (($Enclave.DistinguishedName) -eq "DC=domain,DC=NAVY,DC=MIL"){
    $OU = "DC=NAVY,DC=MIL"
}

#Confirm logging path exists
if (-not (Test-Path $path)) {
    New-Item -Path $path -ItemType Directory | Out-Null
}

#start transcript
Start-Transcript -path c:\

# Loops through lists of domains and sets policy for user mailboxes and groups
foreach ($Domain in $forest) {
    
    #set variables for testing domains
    $result = Test-NetConnection $Domain -WarningAction SilentlyContinue
   
    #test domain to make sure it's reachable and to avoid collecting bad data, skip and proceed if test fails
    if (-not $result.pingsucceeded) {
       "[$(Get-Date)] WARNING: $Domain is not reachable, skipping." | Out-File $logfile -Append
       continue
    } 
    else {
        "[$(Get-Date)] INFO: $Domain is reachable, proceeding." | Out-File $logfile -Append
    }

    #for each domain (except DOMAIN, set the address book policy to match to its domain
    #set variables
    $DomainController = (Get-ADDomain $Domain).PDCEmulator
    $mailboxes = Get-Mailbox -DomainController $DomainController
    $Dom = $Domain.split(".")[0]

    if ($Dom -EQ "DOMAIN" ){
    } else {      
       foreach ($mailbox in $mailboxes){ 
          try {
           Set-Mailbox -Identity $mailbox -CustomAttribute1 $Dom -AddressBookPolicy $Dom -DomainController $DomainController -whatif -ErrorAction Stop | Out-File $logfile -Append
           #Write-Host "mailbox" $mailbox.name $Database.Name
           }
           catch {
            "[$(Get-Date)] ERROR: Failed to set $mailbox ($mailbox.userprincipalname).  Reason: $($_.Exception.Message)" | Out-File $logfile -Append
           }
        }

         # Loop through groups and set Distribution Group custom attribute 1 to Database Name (Hull SSNXXX)
         #Set variable for groups so before we loop through and set policy for them 
         $groups = Get-DistributionGroup -OrganizationalUnit "DC=$Dom,$OU" -DomainController $DomainController
         foreach ($group in $groups){
             try {
                $group | Set-DistributionGroup -CustomAttribute1 $Dom -DomainController $DomainController -whatif -ErrorAction Stop | Out-File $logfile -Append
              }
              catch {
                "[$(Get-Date)] ERROR: Failed to set $group.  Reason: $($_.Exception.Message)" | Out-File $logfile -Append
                #Write-Host "Group" $group.Name $DatabaseName
              }
         }
    }
}
Stop-Transcript # Stop Logging
