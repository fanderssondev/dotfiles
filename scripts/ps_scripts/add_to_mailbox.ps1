param (
    [Parameter(Mandatory = $true)]
    [string]$UserEmail,

    [string[]]$Mailboxes,              # Optional array of mailbox emails via CLI
    [string]$MailboxFilePath           # Optional path to file containing mailboxes
)

# Read credentials from 1Password
# $username = $(op read "op://Employee/admin_credentials/username")
# $password = $(op read "op://Employee/admin_credentials/password")
# $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
# $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Import and connect
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName "fa_admin@piercegroup.com"
# Connect-ExchangeOnline -Credential $credential


# Resolve mailbox source
if ($MailboxFilePath) {
    try {
        $mailboxes = Get-Content -Path $MailboxFilePath | Where-Object { $_.Trim() -ne "" }
    } catch {
        Write-Error "Failed to read mailbox file at path: $MailboxFilePath"
        exit 1
    }
} elseif ($Mailboxes) {
    $mailboxes = $Mailboxes
} else {
    Write-Error "You must provide either -Mailboxes or -MailboxFilePath."
    exit 1
}

# Loop through mailboxes
foreach ($mailbox in $mailboxes) {
    Write-Host "Granting permissions to $UserEmail on $mailbox..."

    try {
        Add-MailboxPermission -Identity $mailbox `
            -User $UserEmail `
            -AccessRights FullAccess `
            -InheritanceType All -ErrorAction Stop

        Add-RecipientPermission -Identity $mailbox `
            -Trustee $UserEmail `
            -AccessRights SendAs -ErrorAction Stop

        Write-Host "Permissions set for $mailbox"
    } catch {
        Write-Warning "Failed to assign permissions for ${mailbox}: $_"
    }
}

Disconnect-ExchangeOnline
