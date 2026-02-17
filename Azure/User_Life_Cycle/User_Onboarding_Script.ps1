# 1. Authenticate to Azure and Fetch Graph Access Token
try {
    Connect-AzAccount -Identity
    $TokenRequest = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
    $GraphToken = $TokenRequest.Token
    Write-Output "Successfully authenticated and retrieved Graph token."
}
catch {
    Write-Error "Authentication Failed: $_"
    return
}

# 2. Fetch API Key from Key Vault securely
$VaultName = "poshportfoliovault"
$SecretName = "mockaroo"
$MockKey = (Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -AsPlainText)

# 3. Fetch New Hire Data from Mockaroo
$ApiUrl = "https://my.api.mockaroo.com/onboarding.json"
$Headers = @{ "X-API-Key" = $MockKey }
$NewHire = Invoke-RestMethod -Uri $ApiUrl -Method Get -Headers $Headers

# 4. Provisioning & Compliance Logic
try {
    # Isolate the first record and ensure it's treated as a single object
    $TargetHire = $NewHire[0]
    if ($null -eq $TargetHire.firstName) { throw "API returned empty data. Check Mockaroo Key/Schema." }
   
    Write-Output "Processing New Hire: $($TargetHire.firstName) $($TargetHire.lastName)"
    
    # Define User Details using TargetHire
    $UPN = "$($TargetHire.firstName).$($TargetHire.lastName)@andyagsec482.onmicrosoft.com"
    
    # Construct the Body Object for Direct API Call
    $UserBodyObj = @{
        accountEnabled    = $true
        displayName       = "$($TargetHire.firstName) $($TargetHire.lastName)"
        mailNickname      = "$($TargetHire.firstName)$($TargetHire.lastName)"
        userPrincipalName = $UPN
        usageLocation     = "US"
        jobTitle          = "$($TargetHire.jobTitle)"
        passwordProfile   = @{
            forceChangePasswordNextSignIn = $true
            password                      = "InitialPassword123!"
        }
    } 
    
    # Convert object to JSON with sufficient depth for nested profiles
    $UserBody = $UserBodyObj | ConvertTo-Json -Depth 10

    # Set up Bearer Token Headers
    $AuthHeader = @{ 
        "Authorization" = "Bearer $GraphToken"
        "Content-Type"  = "application/json"
    }

    # Execute the POST request to Microsoft Graph
    $GraphUserUri = "https://graph.microsoft.com/v1.0/users"
    $NewUser = Invoke-RestMethod -Uri $GraphUserUri -Method Post -Body $UserBody -Headers $AuthHeader
    
    Write-Output "Successfully created user in Entra ID with ID: $($NewUser.id)"

    # 5. Archive to Immutable Vault (Compliance Step)
    $ResourceGroupName  = "PowerShell-Portfolio"
    $StorageAccountName = "userlifecyclelog"     
    $ContainerName      = "compliance-records"

    $LogEntry = [PSCustomObject]@{
        Timestamp    = (Get-Date).ToUniversalTime()
        Event        = "USER_CREATED"
        UserPrincipal= $UPN
        ComplianceID = "SOX-404-CONTROL"
        ApprovedBy   = "$($TargetHire.managerEmail)"
        Status       = "Success"
    }

    # Save log to the Automation temporary local storage
    $LocalPath = "$HOME/audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $LogEntry | ConvertTo-Json | Out-File -FilePath $LocalPath

    # REINFORCED STORAGE LOGIC:
    # Explicitly create a context using the Managed Identity (-UseConnectedAccount).
    # This bypasses the need for Storage Account Keys and works in PS 7.2.
    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

    # Upload the file to the WORM Container
    Set-AzStorageBlobContent -File $LocalPath `
                             -Container $ContainerName `
                             -Blob "Audit-$($NewUser.id).json" `
                             -Context $StorageContext
                             
    Write-Output "Compliance log successfully archived to Immutable Vault."
}
catch {
    Write-Error "Provisioning failed: $_"
}
