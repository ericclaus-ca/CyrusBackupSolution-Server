﻿<#
.SYNOPSIS
    This is the core script of the Server aspect of the Cyrus Backup Solution.

.DESCRIPTION
    This script functions as the core script of the Server aspect of the Cyrus Backup Solution.
    It should be ran from Task Scheduler daily. In it, the frequencies for the NAS1 and VM backups
    are specified and the corresponding scripts called. 

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last Modified: 06/22/2018
    Based on code from Shawn Melton (@wsmelton), http://blog.wsmelton.com

.LINK
    http://doku/doku.php?id=dr:cyrus_documentation
#>

# Start a transcript of the Powershell session for logging
$scriptName = $MyInvocation.MyCommand.Name
$date = Get-Date -Format MM-dd-yyyy-HHmm
$transcript = "$PSScriptRoot\Transcripts\$scriptName.$date.transcript"
Start-Transcript -Path $transcript
$myFunctions = @(
    "$PSScriptRoot\Backup-VM.ps1",
    "$PSScriptRoot\Backup-NAS1.ps1",
    "$PSScriptRoot\Cleanup-Backups.ps1"
    )
$myFunctions | ForEach-Object {
    If (Test-Path $_) {. $_}
    Else {throw "Error: At least one necessary function was not found."; Exit 99}
}
    #if ($hourOfDay -eq 20) {
        # Perform a full backup of the file shares on NAS1
        Backup-NAS1 -Type Full
    #}
}
$backupDir = "\\192.168.90.92\d$\NASShare\dr"
Cleanup-Backups -BackupName "Dokuwiki" -DaysOldToKeep 31 -BackupFolder "$backupDir\dokuwiki"
Cleanup-Backups -BackupName "Spiceworks" -DaysOldToKeep 31 -BackupFolder "$backupDir\spiceworks"
Cleanup-Backups -BackupName "Fortigate" -DaysOldToKeep 365 -BackupFolder "$backupDir\fortinet\Fortigate Config"
Cleanup-Backups -BackupName "Centaur" -DaysOldToKeep 7 -BackupFolder "$backupDir\Centaur"
Cleanup-Backups -BackupName "EOP" -DaysOldToKeep 90 -BackupFolder "$backupDir\EveryonePrint"
Cleanup-Backups -BackupName "NAS" -DaysOldToKeep 56 -BackupFolder "Z:\Cyrus\NASShare"
Cleanup-Backups -BackupName "VMs" -DaysOldToKeep 180 -BackupFolder "V:\VM_Backup"
Cleanup-Backups -BackupName "Xibo" -DaysOldToKeep 31 -BackupFolder "$backupDir\xibo"
