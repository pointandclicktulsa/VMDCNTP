#######
# Script for setting up NTP on a fresh DC on a Hyper-V host you want to join to the domain.
# To-do: swap from "reg" to powershell if possible, same for w32tm
# Improvements?: Change the while loop to have a wait of an hour or longer, and make it send
#                an email to me if it has failed rather than checking every 10 seconds?
#######

# Begin log file, this will be placed on the client the script is being run from, do not modify unless you want to disable logging
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\NTP.txt -append

# VM IC Partial disable (preserves checkpoint/backup restore time fix)
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t reg_dword /d 0 /f

# Add NTP servers
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v NtpServer /t reg_sz /d "0.us.pool.ntp.org,0x1 1.us.pool.ntp.org,0x1 2.us.pool.ntp.org,0x1 3.us.pool.ntp.org,0x1" /f

# Set w32time type to NTP
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v Type /t reg_sz /d NTP /f

# Set poll time to 900 seconds (15 minutes) to prevent VM time drift
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient /v SpecialPollInterval /t reg_dword /d 900 /f

# Restart w32time to refresh settings
Restart-Service w32time

# Force w32time to fetch new time
w32tm /resync /force /nowait

# Check w32time is able to see it's NTP servers ("state: active" means it can talk to the servers)
w32tm /query /peers

# check to see if w32time is actually fetching time from an NTP server rather than CMOS or VM IC
while ((w32tm /query /source) -like "*CMOS*" -or (w32tm /query /source) -like "*VM*")
{
Write-Host "NTP is not configured, trying again in 10 seconds"
Start-Sleep -s 10
}

Write-Host "NTP is Properly configured!"

# End log file
Stop-Transcript