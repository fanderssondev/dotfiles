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

    $OU = "OU=Users,OU=Poland,OU=Pierce,DC=corp,DC=pierce-ecom,DC=com"

    $Users = Get-ADUser -Filter * -SearchBase $OU -Properties `
        DisplayName, 
        EmailAddress, 
        SamAccountName, 
        AccountExpirationDate, 
        Description, 
        Title, 
        Department, 
        Company, 
        Manager, 
        MemberOf,
        Enabled

    $Results = foreach ($User in $Users) {
        $ManagerName = if ($User.Manager) {
            (Get-ADUser $User.Manager -Properties DisplayName).DisplayName
        } else {
            $null
        }

        $GroupNames = @()
        if ($User.MemberOf) {
            $GroupNames = $User.MemberOf | ForEach-Object {
                (Get-ADGroup $_).Name
            }
        }

        [PSCustomObject]@{
            Name           = $User.DisplayName
            Email          = $User.EmailAddress
            Username       = $User.SamAccountName
            ExpirationDate = $User.AccountExpirationDate
            Description    = $User.Description
            JobTitle       = $User.Title
            Department     = $User.Department
            Company        = $User.Company
            Manager        = $ManagerName
            Groups         = ($GroupNames -join ", ")
            Enabled        = $User.Enabled
        }
    }

    return $Results
}

# Invoke the script block remotely
Write-Host "Executing query on $server..."
$usersInfo = Invoke-Command -Session $session -ScriptBlock $scriptBlock

# Output results locally
$usersInfo | Format-Table -AutoSize

# Optional: Export to CSV locally
$usersInfo | Export-Csv -Path "C:\Users\fredrik.andersson\Poland.csv" -NoTypeInformation -Encoding UTF8

# Clean up the session
Remove-PSSession $session
