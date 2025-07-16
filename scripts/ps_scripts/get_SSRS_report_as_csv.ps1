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

# Define the remote script block
$scriptBlock = {
    Import-Module ActiveDirectory

    # Get all groups that start with SSRS and the group SQL30_SmallDeviationModule
    $ssrsGroups = Get-ADGroup -Filter 'Name -like "SSRS*"' -Properties Name
    $sqlGroup = Get-ADGroup -Filter 'Name -eq "SQL30_SmallDeviationModule"' -Properties Name
    $allGroups = $ssrsGroups + $sqlGroup


    $data = foreach ($group in $allGroups) {
        try {
            $members = Get-ADGroupMember -Identity $group -ErrorAction Stop
            foreach ($member in $members) {
                if ($member.objectClass -eq "user") {
                    [PSCustomObject]@{
                        Group = $group.Name
                        User  = $member.SamAccountName
                    }
                }
            }
        } catch {
            Write-Warning "Failed to get members of group $($group.Name): $_"
        }
    }

    return $data
}

# Invoke the remote command
Write-Host "Querying remote server..."
$results = Invoke-Command -Session $session -ScriptBlock $scriptBlock

# Clean up session
Remove-PSSession $session

# Export to CSV
$outputFilePath = "$HOME\Downloads\SSRS_Groups.csv"
$results | Select-Object Group, User | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8

Write-Host "CSV exported to $outputFilePath"
