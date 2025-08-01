$list = Get-Content -Path ./list.txt
$DNSExist = Resolve-DnsName -Name $remoteComputer -ErrorAction SilentlyContinue
foreach($remoteComputer in $list){
    if($DNSExist){
        $HostAvailable = Test-NetConnection -ComputerName $remoteComputer -InformationLevel Quiet
        if($HostAvailable){
            Invoke-Command -ComputerName $remoteComputer -ScriptBlock {Get-Process msiexec | ForEach-Object { $_.Kill() }}
            Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
            Start-Process "msiexec.exe" -ArgumentList "/unreg" -Wait
            Start-Process "msiexec.exe" -ArgumentList "/regserver" -Wait}    
            # Uninstall Adaptive Threat Protection
            $MCatp = Invoke-Command -ComputerName $remoteComputer -ScriptBlock { Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*Adaptive Threat Protection*" }}
            if ($MCatp) {
                Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
                $atp = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*Adaptive Threat Protection*" }
                if ($atp) {
                    Invoke-CimMethod -InputObject $atp -MethodName "Uninstall"
                    }
                }
            }
            # Uninstall McAfee Agent
            $MCAgent = Invoke-Command -ComputerName $remoteComputer -ScriptBlock { Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*McAfee*Agent*" }}
            if($MCAgent){
                $psexecPath = "C:\Temp\PsExec64.exe"      
                $exePath = '"C:\Program Files\McAfee\Agent\x86\FrmInst.exe"'
                $exeArgs = "/FORCEUNINSTALL /SILENT"
                $psexecArgs = "\\$remoteComputer -s $exePath $exeArgs"
                Start-Process -FilePath $psexecPath -ArgumentList $psexecArgs -Wait
            }
            # Uninstall McAfee DLP
            $MCDLP = Invoke-Command -ComputerName $remoteComputer -ScriptBlock { Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*McAfee*DLP*" }}
            if($MCDLP){
                $psexecPath = "C:\Temp\PsExec64.exe"  # ← Local path to PsExec on your machine
                # Step 1: Get uninstall string from remote registry
                $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
                $searchTerm = "McAfee DLP"
                Copy-Item "C:\Temp\PsExec64.exe" -Destination "\\$remoteComputer\C$\Temp\PsExec64.exe" -Force
                $uninstallInfo = Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
                Get-ChildItem $using:uninstallKey | ForEach-Object {
                    $props = Get-ItemProperty $_.PSPath
                    if ($props.DisplayName -like "*$using:searchTerm*") {
                        return $props.UninstallString
                    }
                }
            }
            # Step 2: Build remote PsExec command
            $remoteCmd = "`"$uninstallInfo`" REMOVE=ALL REBOOT=R /q MSIRESTARTMANAGERCONTROL=`"Disable`""
            $psexecCmd = "$psexecPath \\$remoteComputer -s -i cmd /c $remoteCmd"
            #Step 3: Execute PsExec remotely
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c $psexecCmd" -WindowStyle Hidden
            }
            # Uninstall other McAfee Products
            $MCapps = Invoke-Command -ComputerName $remoteComputer -ScriptBlock { Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*McAfee*"}}
            if ($MCapps){
                foreach ($app in $MCapps) {
                    Invoke-Command -ComputerName $remoteComputer -ArgumentList $app.Name -ScriptBlock {
                    param($appName)
                    $target = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -eq $appName }
                    if ($target) {
                        Invoke-CimMethod -InputObject $target -MethodName "Uninstall"
                        Start-Sleep -Seconds 30
                    }
                }
            }
        }
        }else{
            Add-Content -Path ./log.txt -Value "Host $remoteComputer is not available or DNS resolution failed."
        }
    }else{
        Add-Content -Path ./log.txt -Value "DNS resolution failed for $remoteComputer. Please check the hostname or network connectivity."
    }
         
    
    
    
    
    
}