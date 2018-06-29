    <#
    .SYNOPSIS
        This script changes the assigned drive letters of the NAS and VM backup partitions on the Backup External Hard Drives.
     
    .DESCRIPTION
        This script can be scheduled to run with Task Scheduler after every time the backup external hard drives are swapped.
        This eliminates the need to manually change the assigned drive letters. These changes to the assigned drive letters 
        are needed in order for Iperius backup and the Veeam VM backup scripts to run successfully. 
     
    .NOTES
        Author: Eric Claus
        Last Modified: 01/12/2018
     
    .LINK
        https://blogs.technet.microsoft.com/heyscriptingguy/2011/03/14/change-drive-letters-and-labels-via-a-simple-powershell-command/
        https://stackoverflow.com/questions/46557186/wildcard-search-in-filter
     
    .COMPONENT
        Get-WmiObject -Class win32_volume
    #>
     
    $vmPartition = Get-WmiObject -Class win32_volume -Filter "Label like 'VM Backup%'"
    $vmPartition.DriveLetter = "V:"
    $vmPartition.Put()
     
    $nasPartition = Get-WmiObject -Class win32_volume -Filter "Label like 'NAS Backup%'"
    $nasPartition.DriveLetter = "Z:"
    $nasPartition.i
    $nasPartition.Put()
