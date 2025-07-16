# Read credentials from 1Password
Write-Host "Reading credentials from 1Password..."
$username = op read op://Employee/admin_credentials/username
$password = op read op://Employee/admin_credentials/password

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Define the server to connect to
$server = "sesth01-dc11"

# Create the remote session
Write-Host "Creating remote session to $server..."
$session = New-PSSession -ComputerName $server -Credential $credential

# Define the script block to run remotely
$scriptBlock = {
    Import-Module ActiveDirectory

    # List of OUs to search
    $OUS = @(
        "OU=Users,OU=Barcelona,OU=Pierce,DC=corp,DC=pierce-ecom,DC=com",
        "OU=Users,OU=Stockholm,OU=Pierce,DC=corp,DC=pierce-ecom,DC=com",
        "OU=Users,OU=Åre,OU=Pierce,DC=corp,DC=pierce-ecom,DC=com",
        "OU=Users,OU=Poland,OU=Pierce,DC=corp,DC=pierce-ecom,DC=com",
        "OU=Consultants_Users_Contacts,OU=Pierce,DC=corp,DC=pierce-ecom,DC=com"
    )

    $Results = foreach ($ou in $OUS) {
        Get-ADUser -Filter * -SearchBase $ou -Properties EmailAddress, Enabled | Where-Object {
            $_.Enabled -eq $true -and $_.EmailAddress -ne $null
        } | Select-Object EmailAddress
    }

    return $Results
}

# Invoke the script block remotely
Write-Host "Executing query on $server..."
$usersInfo = Invoke-Command -Session $session -ScriptBlock $scriptBlock

# Output results locally
# $usersInfo | Format-Table -AutoSize

# Optional: Export to CSV locally
$usersInfo | Export-Csv -Path "C:\Users\fredrik.andersson\Downloads\enabled_users_AD.csv" -NoTypeInformation -Encoding UTF8

# Clean up the session
Remove-PSSession $session
