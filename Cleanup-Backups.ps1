Function Cleanup-Backups {
    <#
    .SYNOPSIS
        This is a Powershell script which cleans up old files.
        Used to comply with retention policies for various backups.
    
    .DESCRIPTION
        This script can be used in order to comply with the retention policy for backups stored on NAS1.The script      
        removes backups that are outside the time frame for the corresponding retention policy. For example, if a 
        retention policy states that a particular backup should be kept for 31 days, this script can delete any 
        backups that are more than 31 days old. It can be used in conjunction with Task Scheduler to automate the 
        process. Multiple backups can be configured in this script, each with their own retention policy settings.
    
        Each seperate item being backed up (eg. software, files, configurations, or other items) can be listed in the
        script, along with the directory its backups are located in, the time span (in days) of backups to keep, and
        optionally, a specific extension to delete and a custom log file location. 
    
        The function which performs the deletion, Cleanup-Backups (not to be confused with the name of the script...),
        is called seperately for each item who's backups are being cleaned up. See the script for examples.
    
    .NOTES
        Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
        Last Modified: 05/10/2018
        Modified from: http://www.networknet.nl/apps/wp/published/powershell-delete-files-older-than-x-days
    
    .LINK
        http://doku/doku.php?id=dr:cleanup-backups
    #>

    Param(
        [Parameter(Mandatory=$true)] [string]$BackupName,
        [Parameter(Mandatory=$true)] [int]$DaysOldToKeep,
        [Parameter(Mandatory=$true)] [string]$BackupFolder,
        [string]$Extension="*",
        [string]$LogFile="myTempSource:\dr\Logs\Cleanup-Backups-$BackupName.log"
    )

    # Include the neccasary functions
    $myFunctions = @(
        "$PSScriptRoot\Get-SecurePassword.ps1"
        )
    $myFunctions | ForEach-Object {
        If (Test-Path $_) {. $_}
        Else {throw "Error: At least one necessary function was not found."; Exit 99}
    }

    # Create a PSCredential object with the password for the domain backup VLAN admin account
    $creds = Get-SecurePassword -PwdFile "$PSScriptRoot\130294490" -userName "ad\Cyrus"
        
    # What is being backed up
    $backupSource = "\\192.168.90.92\d$\NASShare"

    # Create a temporary mapped drive, connecting to the backup source folder with the credentials from above
    Remove-PSDrive -Name "myTempSource" -ErrorAction SilentlyContinue
    New-PSDrive -Name "myTempSource" -PSProvider FileSystem -Root $backupSource -Credential $creds
    $source = "myTempSource:\"

    # For the log
    echo "------------------------------------------------------" >>$LogFile
    echo "Performing cleanup of the $BackupName backups." >>$LogFile

    $date = Get-Date
    echo $date >>$LogFile

    # Set $lastWrite to a DateTime object that is the current date minus $DaysOldToKeep
    $lastWrite = $date.AddDays(-$DaysOldToKeep)
    echo "LastWrite date = $lastWrite" >>$LogFile

    # Get files from the backup folder with the specified extension, if it is older than the time specified in $DaysOldToKeep
    $Files = Get-Childitem $BackupFolder -Recurse -Filter "*.$Extension" | Where {$_.LastWriteTime -le "$LastWrite"}	 

    # If there are no files to be deleted
    if ($Files -eq $NULL) {
        echo "No files to delete today!" >>$LogFile
    }

    # Loop through each file and delete it.
    foreach ($File in $Files) {
	    if ($File -ne $NULL) {
	        echo "Deleting File $File" >>$LogFile
	        Remove-Item -LiteralPath $File.FullName -Recurse
	    }
    }
}