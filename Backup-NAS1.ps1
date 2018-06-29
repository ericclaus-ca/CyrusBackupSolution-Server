function Backup-NAS1 {
    <#
    .SYNOPSIS
        Performs Full or Incremental backups on the NAS.    

    .DESCRIPTION
        This function uses the 7Zip4PowerShell module to compress, encrypt, and backup the file shares on NAS1.
        All folders inside of the NASShare folder on NAS1 are backed up.

        When an incremental backup is performed, only files modifed since the last backup was completed will be backed up.
        
        Requirements:
            * Must have access to (ie. on the same user account and computer as) the secure password file containing the backup encryption key.
            * Must have access to (ie. on the same user account and computer as) the secure password file containing the backup VLAN admin account password.

    .EXAMPLE
        Backup-NAS1 -Type Full
        Perform a full backup of the file shares on NAS1

    .EXAMPLE
        Backup-NAS1 -Type Incremental
        Perform an incremental backup of the file shares on NAS1 

    .NOTES
        Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
        Last modified: 06/22/2018
        Thanks to Thomas Freudenberg for his module and his help with getting the incremental backup to work.

    .LINK
        https://github.com/thoemmi/7Zip4Powershell

    .COMPONENT
        7Zip4PowerShell
    #>

    #Requires –Modules 7Zip4PowerShell
    #Uncomment line below to install the module
    #Install-Module -Name 7Zip4PowerShell

    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Full", "Incremental")]
        [string]$Type
    )
    
    $date = Get-Date -Format MM-dd-yyyy-HHmm
    
    # Include the neccasary functions
    $myFunctions = @(
        "$PSScriptRoot\Get-SecurePassword.ps1"
        )
    $myFunctions | ForEach-Object {
        If (Test-Path $_) {. $_}
        Else {throw "Error: At least one necessary function was not found."; Exit 99}
    }

    # Folder the backup file will reside in (make it if it doesn't exist)
    $destination = "Z:\Cyrus\NASShare"
    if (!(Test-Path $destination)) {mkdir $destination}

    # Create a PSCredential object with the password for the domain backup VLAN admin account
    $securePassFile = "$PSScriptRoot\130294490"
    $userName = "ad\Cyrus"
    $creds = Get-SecurePassword -PwdFile $securePassFile -userName $userName
    
    # What is being backed up
    $backupSource = "\\192.168.90.92\d$\NASShare"
    
    # Create a temporary mapped drive, connecting to the backup source folder with the credentials from above
    Remove-PSDrive -Name "tempSource" -ErrorAction SilentlyContinue
    New-PSDrive -Name "tempSource" -PSProvider FileSystem -Root $backupSource -Credential $creds
    $source = "tempSource:\"
    
    # Files/folders to exclude from being backed up, regular expression
    $exclude = "\\home\\mlavertue|\\ICE_INS\\|\\Overall Desktop A\\Corsair\\|\\yearbook\\backup 2017|\\yearbook\\backup 2016|\\CONERLKE\\conerlke\\Google Drive\\|conerlke\\Documents\\Documents 10.26.12\\|\\Backpup files from Julian|02-04-18.tar.gz|\\djernesd.AD\\AppData|\\djernesd\\AppData"
    
    # Get the password to encrypt the backup with
    $nasBackupZipPassword = (Get-SecurePassword -PwdFile "$PSScriptRoot\455799013").Password
    
    # What compression level to use, options are: Ultra, High, Fast, Low, None, and Normal
    $compressionLevel = "Fast"
    
    if ($Type -eq "Incremental") {
        $backupLog = "$destination\BackupLog-INCREMENTAL-$date.txt"
        
        # Get the creation time of the most recent backup
        $lastWrite = (Get-ChildItem -Path $destination -Filter "NASShare-*").CreationTime | Sort-Object | Select-Object -Last 1
        Write-Output "Backing up files modifed since: $lastWrite"
    
        $destinationFile = "$destination\NASShare-INCREMENTAL-$date.7z"
        
        Get-ChildItem $source -Recurse -File |              # Get a list of files in the backup source folder
            Where-Object {$_.FullName -notmatch $exclude} | # Filter out the items listed in the exclude list above
            Where-Object {$_.LastWriteTime -ge "$LastWrite"} |     # Only get the files that have been modified since the last backup
            % {$_.FullName} |                               # Get their full path names
            Compress-7Zip -Format SevenZip -ArchiveFileName $destinationFile -SecurePassword $nasBackupZipPassword -CompressionLevel $compressionLevel
    }
    elseif ($Type -eq "Full") {
        $backupLog = "$destination\BackupLog-FULL-$date.txt"
        
        $destinationFile = "$destination\NASShare-FULL-$date.7z"
    
        Get-ChildItem $source -Recurse -File |              # Get a list of files in the backup source folder
            Where-Object {$_.FullName -notmatch $exclude} | # Filter out the items listed in the exclude list above
            % {$_.FullName} |                               # Get their full path names
            Compress-7Zip -Format SevenZip -ArchiveFileName $destinationFile -SecurePassword $nasBackupZipPassword -CompressionLevel $compressionLevel
        
        # Delete any previous incremental backups (restart incremental backups every time a full backup is run)
        Remove-Item -Path "$destination\*" -Filter "*INCREMENTAL*"
    }

    # Get a list of items in the new backup file (files that were backed up) and send the list to the backup log
    (Get-7Zip -ArchiveFileName $destinationFile).FileName | Out-File $backupLog -Append
    
    # The drive created should be removed once the Powershell session ends, however, this makes sure it goes away
    Remove-PSDrive -Name "tempSource" -ErrorAction SilentlyContinue
}