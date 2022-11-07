<#

.NAME
    Get-LR-Alarm-Report

.SYNOPSIS
    Generate a report showing alarm activity

.DESCRIPTION

Written by:   Soren Frederiksen
Date:         November 3 2022

The program uses LogRhythm Tools to connect to a LogRhythm deployment and generates a report showing alarm activity for a specific day

#>

param(

  [Parameter(Mandatory=$false)] [string]$currentDate = ''

)

Import-Module logrhythm.tools

# List of Alarm rules that should not be included in the count.

$ignoreAlarm = @("Networkx",
                 "third rule"
                 )

if ($currentDate -eq "" )
    {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
    }

# Now set $alarmDate to be one less than current day.  Will use this date to run Get-LRAlarms.  This is because the Alarms are returned in UTC time
$alarmDate = (Get-Date $currentDate).AddDays(-1)
#$alarmDate = $alarmDate.ToString("yyyy-MM-dd")

# Now need to set a start and end times for collecting alarms based on UTC time
$startDate = (get-date $currentDate).ToUniversalTime()
$startDate = Get-Date $startdate -Format ("yyyy-MM-ddThh:mm:ss")
$endDate = (get-date $currentDate).Adddays(1).ToUniversalTime()
$endDate = Get-Date $enddate -Format ("yyyy-MM-ddThh:mm:ss")


# Run Get-Alarms and collect all logs
$allAlarms = Get-LrAlarms -ResultsOnly -DateInserted $alarmDate| Where-Object dateInserted -ge $startDate | Where-Object dateInserted -le $endDate | sort-object alarmId -unique

foreach ($ignore in $ignorealarm)
    {
        $allAlarms = $allAlarms | Where-Object alarmRuleName -CNotlike "*$ignore*"
    }



######$allAlarms = Get-LrAlarms -ResultsOnly | Where-Object -Property AlarmDataCached -eq Y | Where-Object dateInserted -CLike "$currentDate*" | Where-Object alarmRuleName -CNotlike "*$ignoreAlarm*"

# Now collect alarms of each status types (types 1-9)

$newAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 0 
$openedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 1
$workingAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 2
$escalatedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 3
$closedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 4
$falseAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 5
$monitorAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 6
$reportedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 7
$resolvedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 8
$unresolvedAlarms = $allAlarms | Where-Object -Property alarmStatus -eq 9

$assignedAlarms = $allAlarms | Where -Property associatedCases -ne ""


$totalOpenedAlarms = @($newAlarms).count + @($openedAlarms).count + @($workingAlarms).count + @($escalatedAlarms).count
$totalClosedAlarms = @($closedAlarms).count + @($falseAlarms).count + @($monitorAlarms).count + @($reportedAlarms).count + @($resolvedAlarms).count + @($unresolvedAlarms).count
$unassignedAlarms = @($allAlarms).count - @($assignedAlarms).count



Write-Host "SIEM Alarm Summary for  $currentDate"
Write-Host "Number of SIEM Alarms opened:         " $totalOpenedAlarms
Write-Host "Number of SIEM Alarms closed:         " $totalClosedAlarms
Write-Host "Number of Siem Alarms unassigned:     " $unassignedAlarms
Write-Host "Number of Siem Alarms assigned:       " @($assignedAlarms).count