# Kill any existing msiexec processes
Get-Process msiexec -ErrorAction SilentlyContinue | ForEach-Object { $_.Kill() }
# Re-register Windows Installer
Start-Process "msiexec.exe" -ArgumentList "/unreg" -Wait
Start-Process "msiexec.exe" -ArgumentList "/regserver" -Wait
# Uninstall Adaptive Threat Protection
$MCatp = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*Adaptive Threat Protection*" }
if ($MCatp) {
    Invoke-CimMethod -InputObject $MCatp -MethodName "Uninstall"
}
# Uninstall McAfee Agent
$MCAgent = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*McAfee*Agent*" }
if ($MCAgent) {
    $exePath = "C:\Program Files\McAfee\Agent\x86\FrmInst.exe"
    $arguments = "/FORCEUNINSTALL /SILENT"
    Start-Process -FilePath $exePath -ArgumentList $arguments -Verb RunAs -Wait
}
# Uninstall McAfee DLP with SYSTEM privileges
$MCDLP = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*McAfee*DLP*" }
if ($MCDLP) {
    $uninstallKeyPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    $dlpUninstallString = $null
    foreach ($key in $uninstallKeyPaths) {
        $dlpUninstallString = Get-ChildItem $key | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath
            if ($props.DisplayName -like "*McAfee*DLP*") {
                return $props.UninstallString
            }
        }
        if ($dlpUninstallString) { break }
    }
    if ($dlpUninstallString) {
        $taskName = "TempSystemDLPRemoval"
        $command = "cmd.exe /c msiexec /x $dlpUninstallString REMOVE=ALL REBOOT=R /quiet MSIRESTARTMANAGERCONTROL=Disable"
        # Create and run SYSTEM-level task
        schtasks /Create /TN $taskName /RU "SYSTEM" /SC ONCE /ST 00:00 /TR "$command"
        schtasks /Run /TN $taskName
        #checking if DLP has been removed to continue with next products
        do {
            Start-Sleep -Seconds 15
            $dlpExists = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
            Where-Object { (Get-ItemProperty $_.PSPath).DisplayName -like "*McAfee*DLP*" }
            Write-Host "DLP still installed...waiting." -ForegroundColor Yellow
        } while ($dlpExists)
        Write-Host "DLP uninstall completed." -ForegroundColor Green
        # Cleanup
        Start-Sleep -Seconds 10
        schtasks /Delete /TN $taskName /F
    } else {
        Write-Output "Uninstall string for McAfee DLP not found."
    }
}
# Uninstall remaining McAfee products
$MCapps = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*McAfee*" }
foreach ($app in $MCapps) {
    $target = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -eq $app.Name }
    if ($target) {
        Invoke-CimMethod -InputObject $target -MethodName "Uninstall"
        Start-Sleep -Seconds 30
    }
}