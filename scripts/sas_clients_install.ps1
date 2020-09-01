param (
	[string]$stg_acc_name,
	[string]$stg_key,
	[string]$drive_ltr,
	[string]$depot_folder_name,
	[string]$clients_install_properties
)
Set-PSDebug -Trace 1;
$logdir = "C:\saslog"
#$stg_acc_name
#$drive_ltr
#$stg_key
#$depot_folder_name
#$clients_install_properties
$connectTestResult = Test-NetConnection -ComputerName "${stg_acc_name}.file.core.windows.net" -Port 445

if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
	Set-PSDebug -Trace 1;
    cmd.exe /C "cmdkey /add:`"${stg_acc_name}.file.core.windows.net`" /user:`"Azure\${stg_acc_name}`" /pass:`"${stg_key}`""
    # Mount the drive
    New-PSDrive -Name ${drive_ltr} -PSProvider FileSystem -Root "\\${stg_acc_name}.file.core.windows.net\${depot_folder_name}" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
#SET inst_prop="${drive_ltr}:\common\responsefiles\clients_install.properties"

cd "${drive_ltr}:\${depot_folder_name}"
pwd
#Start-Sleep -Seconds 60
#net use ${drive_ltr}: \\${stg_acc_name}.file.core.windows.net\${depot_folder_name} /u:Azure\${stg_acc_name}
.\setup.exe -lang en -deploy -datalocation C:\saslog -responsefile ${drive_ltr}:${clients_install_properties} -quiet 
Start-Sleep -Seconds 12

$latest = Get-ChildItem -Path ${logdir}\deployw* | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$latest.name
cd $logdir
$sort_string = Select-String -Path $latest.name -Pattern "ExitInstance="
$alert = $sort_string | Select-String -pattern "ExitInstance=0" -notMatch
if ($alert) { 
    throw "Install Is Failed"
    }
else {
    Write-Host "Install Is Sucess"
}

$Path = $env:TEMP; $Installer = "chrome_installer.exe"; Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer; Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait; Remove-Item $Path\$Installer

#powershell -ExecutionPolicy Unrestricted -File .\mount.ps1 -stg_acc_name ccuksa -stg_key asdasfsffssf -drive_ltr M -depot_folder_name sasdepot -clients_install_properties "\common\responsefiles\clients_install.properties"