# Takes the users email address as an argument
param (
    [Parameter(Mandatory = $true)]
    [string]$Email
)

# Read credentials from 1Password
$username = $(op read "op://Employee/admin_credentials/username")
$password = $(op read "op://Employee/admin_credentials/password")
# Convert password to secure string
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
# Create PSCredential object
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)


# Connect to Exchange Online using credentials
Import-Module ExchangeOnlineManagement | Out-Null
Connect-ExchangeOnline -Credential $credential

# Get all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# List of mailboxes the user has FullAccess to
$accessibleMailboxes = @()

foreach ($mailbox in $sharedMailboxes) {
    $permissions = Get-MailboxPermission -Identity $mailbox.Alias | Where-Object {
        $_.User -like $Email -and $_.AccessRights -contains "FullAccess" -and $_.IsInherited -eq $false
    }

    if ($permissions) {
        $accessibleMailboxes += $mailbox.DisplayName
    }
}

# Output the shared mailboxes the user has access to
if ($accessibleMailboxes.Count -gt 0) {
    Write-Host "Shared mailboxes accessible by ${Email}:"
    $accessibleMailboxes | ForEach-Object { Write-Host "- $_" }
} else {
    Write-Host "No shared mailbox access found for $Email"
}

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false
