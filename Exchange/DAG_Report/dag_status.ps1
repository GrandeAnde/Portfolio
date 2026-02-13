##### This script will get relevant data about the health of an Exchange DAG and report it via CSV file.  The user then will review and organize the report as needed.
##### This was written in response to an influx of noisy email alerts and reports, and requires user intervention to open the report and assess the information. While still passive, it required a human-in-the-loop to assure data is accurate. 
##### All variables need to be defined in the accompnying config.json to maximal portability and reusability. 
#### Written by Andy Gallegos 2/13/2026


# Set pssession information
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange  -connectionuri http://ex01.domain.com/PowerShell  -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking -Module 

# --- MAIN SCRIPT EXECUTION ---

# Load the configuration from the JSON file.
$Configuration = Get-Content -Path ".\config.json" | ConvertFrom-Json


# --- FUNCTION DEFINITIONS ---

# Function One: Checks DAG and Database Health
function Get-DagHealth {
    param(
        [Parameter(Mandatory=$true)]
        $Configuration
    )

    $results = @()
    $serversToUse = $Configuration.Environment.ExchangeServers
    $DC = $Configuration.Environment.DomainControllers

    try {
        # --- CHECK 1: GENERAL DAG OVERVIEW ---
        $dagInfo = Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop
        foreach ($dag in $dagInfo) {
            $results += [PSCustomObject]@{
                PSTypeName   = 'My.Exchange.HealthCheck'
                ComputerName = $dag.PrimaryActiveManager
                CheckType    = 'DAG Overview'
                ObjectName   = $dag.Name
                Result       = 'Info'
                Status       = 'N/A'
                Details      = "Witness: $($dag.WitnessServer), Servers: $($dag.Servers -join ', ')"
            }
        }

        # --- CHECK 2: PER-SERVER CHECKS ---
        foreach ($EX in $serversToUse) {
            # Replication Health check
            $replicationhealth = Test-ReplicationHealth -Identity $EX -ErrorAction Stop
            foreach ($check in $replicationhealth) {
                $results += [PSCustomObject]@{
                    PSTypeName   = 'My.Exchange.HealthCheck'
                    ComputerName = $EX
                    CheckType    = 'DAG Replication'
                    ObjectName   = $check.Check
                    Result       = if ($check.Result -eq 'Passed') { 'OK' } else { 'FAIL' }
                    Status       = $check.Result
                    Details      = $check.ErrorMessage
                }
            }

          
            # --- CHECK 3: DATA BASE COPY STATUS --- 
            $dbCopyResults = Get-MailboxDatabaseCopyStatus -Server $EX -DomainController $DC -ErrorAction Stop
            foreach ($dbCopy in $dbCopyResults) {
                $results += [PSCustomObject]@{
                    PSTypeName   = 'My.Exchange.HealthCheck'
                    ComputerName = $EX
                    CheckType    = 'Database Copy Status'
                    ObjectName   = $dbCopy.Name
                    Result       = if ($dbCopy.Status -eq 'Mounted' -or $dbCopy.Status -eq 'Healthy') { 'OK' } else { 'FAIL' }
                    Status       = $dbCopy.Status
                    Details      = $dbCopy.InternalStartupMessage
                }
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            PSTypeName   = 'My.Exchange.HealthCheck'
            ComputerName = 'N/A'
            CheckType    = 'Function Error'
            ObjectName   = 'Get-DagHealth'
            Result       = 'FAIL'
            Status       = 'Error'
            Details      = "A critical error occurred. Error: $($_.Exception.Message)"
        }
    }

    return $results
}

# Function Two: Checks Mail Queues
function Get-MailflowHealth {
    param(
        [Parameter(Mandatory=$true)]
        $Configuration
    )

    $results = @()
    $serversToUse = $Configuration.Environment.ExchangeServers
    $DC = $Configuration.Environment.DomainControllers

    try {
        # --- CHECK 1: MAIL QUEUE ---
        foreach ($EX in $serversToUse) {
            $queues = Get-Queue -Server $EX -ErrorAction Stop
            foreach ($queuecheck in $queues) {
                # FINAL FIX #1: All properties MUST be inside the @{ ... } block.
                $results += [PSCustomObject]@{
                    PSTypeName   = 'My.Exchange.HealthCheck'
                    ComputerName = $EX
                    CheckType    = 'Queue Health'
                    ObjectName   = $queuecheck.Identity
                    Result       = if ($queuecheck.MessageCount -gt $Configuration.Thresholds.QueueCount) { 'FAIL' } else { 'OK' }
                    Status       = $queuecheck.Status
                    Details      = "Message Count: $($queuecheck.MessageCount) (Threshold: $($Configuration.Thresholds.QueueCount))"
                } # This brace now correctly closes the PSCustomObject.
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            PSTypeName   = 'My.Exchange.HealthCheck'
            ComputerName = 'N/A'
            CheckType    = 'Function Error'
            ObjectName   = 'Get-MailflowHealth' 
            Result       = 'FAIL'
            Status       = 'Error'
            Details      = "A critical error occurred. Error: $($_.Exception.Message)"
        }
    }

    return $results
}

# --- Now you can call your function and out put report---
$healthData = Get-DagHealth -Configuration $configuration
$healthData += Get-MailflowHealth -Configuration $Configuration
$healthData | Sort-Object -Property CheckType | Export-Csv -path .\statuscheck.csv -NoTypeInformation
Write-Host "Report saved to .\statuscheck.csv" -ForegroundColor Green


Remove-PSSession $Session
