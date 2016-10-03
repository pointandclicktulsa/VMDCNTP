#######
# Script for setting up NTP on a fresh DC on a Hyper-V host you want to join to the domain.
# To-do: Test on a fake DC, swap from "reg" to powershell if possible, same for w32tm
#######

# VM IC Partial disable (preserves checkpoint/backup restore time fix)
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t reg_word /d 0

# Add NTP servers
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v NtpServer /t reg_sz /d "0.us.pool.ntp.org,0x1 1.us.pool.ntp.org,0x1 2.us.pool.ntp.org,0x1 3.us.pool.ntp.org,0x1"

# Set w32time type to NTP
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v Type /t reg_sz /d NTP

# Set poll time to 900 seconds (15 minutes) to prevent VM time drift
reg add HKLM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient /v SpecialPollInterval /t reg_word /d 900

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
