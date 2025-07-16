# Prerequisites
# Set up 1Password CLI: https://developer.1password.com/docs/cli/get-started/

# Make sure you have already run:
#   op signin <your_account>
# This can be set to run on shell startup by adding `op signin` to 
# `C:\Users\<YourUsername>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
#                ^ replace

# Signs in 1Password in the shell
# op signin

# How to get the string for username and password
# Make sure your admin credential is saved in 1Password with for example the title "admin_credentials":
# username => xx_admin@piercegroup.com
# password => xxxxxxxxxxxxx

# To find names run `op item get admin_credentials` or simply reteive them from 1Password
# construct a string for the username and one for the password with `op read op://<vault-name>/<item-name>/<field-name>`
Write-Host "Reading credentials from 1Password..."
$username = op read op://Employee/admin_credentials/username
$password = op read op://Employee/admin_credentials/password

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

$server = "sesth01-itops01"

Write-Host "Invoking remote commands on sesth01-itops01..."
Invoke-Command -ComputerName $server -Credential $credential -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Delta
}
