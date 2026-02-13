###### This script will generate a CSV report xyzdomain senders and subjects within the last X hours, it can then be used to determine noisy alerts.  This data can then be used to clean up alerting to make it more meaningful. #######
###### This report does NOT provide a total count of senders.  It's main purpose is to find instances of email alerts being send unnecessarily, too often, or to too many individual mailboxes ######

# Set pssession information
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange  -connectionuri http://ex01.domain.com/PowerShell  -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking -Module 

#Establish beginning/end dates of search
$startdate = (get-date).Addhours(-16)
$enddate = (get-date)

# The "Whitelist"
# These are senders we TRUST and KNOW are good reports/alerts, so we exclude them from the report to reduce noise.
$ExemptList = @(
    "ceo@domain1.com",
    "authorized-scanner@domain1.com"
    "alert.being.test@domain1.com"
)

###### Core Logic #####
###### WARNING: if subject line shows "undisclosed", make sure you modify Exchange Transport Rule settings and restart service. (get-transportservce |Select-Object name, messagetrackinglogsubjectloggingenabled)

$TOPTRAFFIC = Get-ExchangeServer | Get-messagetrackinglog -Source SMTP -resultsize unlimited -start $startdate -end $enddate |  

    #Filter #1: We only look for RECEIVE events because it counts the number of times a device connected to the server, i.e. connected 10 times to send 10 emails to 10 admins, vs 1 time to send to 1 shared mailbox. 
    #this is better for filtering out events of misconfigured alerts
    Where-Object 
    {$_.eventid -eq "RECEIVE" -and 
     $_.sender -like "*@domain1.com" -and 
     $_.sender -notin $ExpemptList
     }  |
     
    #All of the above messages are stored in $TOPTRAFFIC and are then stripped down to WHEN(time stamp) WHO(sender,receiver), WHY (subject).
    Group-Object -Property TimeStamp, Sender, Recipients, Messagesubject |
    #Sort list by worst offenders
    Sort-Object count -Descending |
    #Take above data and turn it back into readable format with key value pair presented in columns
    Select-Object Count,
                  @{Name="Time"; Expression={$_.Group[0].TimeStamp}},
                  @{Name="Sender"; Expression={$_.Group[0].Sender}},
                  @{Name="Recipients"; Expression={$_.Group[0].Recipients}},
                  @{Name="Subject"; Expression={$_.Group[0].MessageSubject}}

$TOPTRAFFIC | Export-Csv -LiteralPath 'c:\scripts\noisealerts.csv' -NoTypeInformation
