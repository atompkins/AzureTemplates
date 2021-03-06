function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$InstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlAlwaysOnAvailabilityGroupName
	)

	$returnValue = @{
		InstanceName = $InstanceName
		SqlAlwaysOnAvailabilityGroupName = $SqlAlwaysOnAvailabilityGroupName
	}

}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$InstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlAlwaysOnAvailabilityGroupName,

		[System.Management.Automation.PSCredential]
		$DomainCredential
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

    throw "Set function should not be executed"
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$InstanceName,

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlAlwaysOnAvailabilityGroupName,

		[System.Management.Automation.PSCredential]
		$DomainCredential
	)

	
	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $result = $true
    $AvailabilityGroup = icm . {Test-SqlAvailabilityGroup -Path SQLSERVER:\SQL\$using:InstanceName\DEFAULT\AvailabilityGroups\$using:SqlAlwaysOnAvailabilityGroupName} -Credential $DomainCredential
    foreach($item in $AvailabilityGroup)
    {
        Write-Verbose -Message ("HealthState:{0} Name:{1}" -f $item.HealthState, $item.Name) -Verbose
    }

    if(($AvailabilityGroup | ? HealthState -NE "Healthy").Count -gt 0)
    {
        $result = $false
        Write-Verbose -Message "Test-SqlAvailabilityGroup failed"
    }
    
    $AvailabilityReplicas = icm . {Get-ChildItem SQLSERVER:\SQL\$using:InstanceName\DEFAULT\AvailabilityGroups\$using:SqlAlwaysOnAvailabilityGroupName\AvailabilityReplicas | Test-SqlAvailabilityReplica} -Credential $DomainCredential
    foreach($item in $AvailabilityReplicas)
    {
        Write-Verbose -Message ("HealthState:{0} AvailabilityGroup:{1} AvailabilityReplica:{2} Name:{3}" -f $item.HealthState, $item.AvailabilityGroup, $item.AvailabilityReplica, $item.Name) -Verbose
    }

    if(($AvailabilityReplicas | ? HealthState -NE "Healthy").Count -gt 0)
    {
        $result = $false
        Write-Verbose -Message "Test-SqlAvailabilityReplica failed"
        
    }

    $DatabaseReplicaStates = icm . {Get-ChildItem SQLSERVER:\SQL\$using:InstanceName\DEFAULT\AvailabilityGroups\$using:SqlAlwaysOnAvailabilityGroupName\DatabaseReplicaStates | Test-SqlDatabaseReplicaState} -Credential $DomainCredential
    foreach($item in $DatabaseReplicaStates)
    {
        Write-Verbose -Message ("HealthState:{0} AvailabilityGroup:{1} AvailabilityReplica:{2} Name:{3}" -f $item.HealthState, $item.AvailabilityGroup, $item.AvailabilityReplica, $item.Name) -Verbose
    }

    if(($DatabaseReplicaStates | ? HealthState -NE "Healthy").Count -gt 0)
    {
        $result = $false
        Write-Verbose -Message "Test-SqlDatabaseReplicaState failed"
    }

    if(-not $result)
    {
        throw "Verify Always On Group failed."
    }

   $result
}

Export-ModuleMember -Function *-TargetResource

