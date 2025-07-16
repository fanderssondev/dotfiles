param (
    [Parameter(Mandatory = $true)]
    [string]$DistributionGroupEmail,

    [Parameter(Mandatory = $true)]
    [string]$OutPutFileName,

    [string]$OutputFolder
)

# Determine export path based on DistributionEmail
if (-not $OutputFolder) {
    $exportPath = "C:\Users\fredrik.andersson\Downloads\$OutPutFileName"
}
elseif ($OutputFolder -ieq "linux") {
    $exportPath = "\\wsl.localhost\Ubuntu-24.04\home\fredrik\$OutPutFileName"
}
else {
    $exportPath = "$OutputFolder\$OutPutFileName"
}

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
    param ($Email)
    Import-Module ActiveDirectory

    # Get the distribution group by email address
    $group = Get-ADGroup -Filter {Mail -eq $Email}
    if ($null -eq $group) {
        Write-Error "No distribution group found with email $Email"
        return $null
    }

    # Get group members
    $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive | Where-Object { $_.ObjectClass -eq 'user' }

    # Get email addresses of members
    $members | ForEach-Object {
        Get-ADUser $_ -Properties mail | Select-Object -ExpandProperty mail
    }
}

# Execute remotely
Write-Host "Querying distribution list members..."
$emails = Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $DistributionGroupEmail

# Display output
$emails | Format-Table -AutoSize

# Export to CSV
$emails | Out-File -FilePath $exportPath -Encoding UTF8

# Clean up
Remove-PSSession $session
