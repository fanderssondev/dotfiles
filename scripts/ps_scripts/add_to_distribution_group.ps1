param (
    [Parameter(Mandatory = $true)]
    [string]$GroupName,
	
	[Parameter(Mandatory = $true)]
    [string]$EmailListFilePath           # Optional path to file containing mailboxes
)

# Import and connect
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName "fa_admin@piercegroup.com" # Replace with actual admin account

# Read email addresses
$emailAddresses = Get-Content $EmailListFilePath

# Loop through and add each user
foreach ($email in $emailAddresses) {
    try {
        Add-DistributionGroupMember -Identity $groupName -Member $email -ErrorAction Stop
        Write-Host "Added $email to $groupName"
    } catch {
        Write-Host "Failed to add ${email}: $_"
    }
}

Disconnect-ExchangeOnline
