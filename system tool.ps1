#this PowerShell script provides a menu-driven system administrator tool that allows the user to perform various administrative tasks such as renaming a domain controller, setting up a new domain, configuring DHCP, creating DNS zones, managing user accounts and groups, and more.
$continue = 'y'
while ($continue -eq 'y') {
 
write-host "Welcome to the system administrator tool :) 

select:
1: rename a DC (Do before runing commamd 2 or 3)
2: set New domain,AD and dhcp
3: set Another domain controler,AD and DHCP
4: new DNS zone
5: new DHCP scope
6: DHCP Failover
7: new Share folder
8: setup Work folder feature (beta)
9: new DNS Zone backup
10: new User
11: new Group
12: new OU
13: set a roaming profile for user
14: add user to a gruop (in beta)
15: backup GPO to a folder
16: restore GPO from a folder" -BackgroundColor Cyan -ForegroundColor Black


        
$selection = Read-Host "enter the disarable commamd" 

Switch ($selection){

1 {$DC_name=Read-Host "enter the DC server name (warning! the server will be restert after the command will run!)"
    Rename-Computer -NewName $DC_name
    Restart-Computer -ComputerName localhost}

2 {$ip=Read-Host "set the DC static ip address"
    $dg=Read-Host "DefaultGateway"
    $domain_name=Read-Host "set the domain name"
    New-NetIPAddress �IPAddress $ip -DefaultGateway $dg -PrefixLength 24 -InterfaceIndex (Get-NetAdapter).InterfaceIndex
    Set-DNSClientServerAddress �InterfaceIndex (Get-NetAdapter).InterfaceIndex �ServerAddresses $ip
    Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSForest  -DomainMode "WinThreshold" -DomainName $domain_name -ForestMode "WinThreshold" -InstallDns -Force
    Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
    Install-WindowsFeature -Name 'DHCP' �IncludeManagementTools -IncludeAllSubFeature
    Add-DhcpServerInDC -DNSName $domain_name } 

3 {$ip=Read-Host "set the DC static ip address"
    $dg=Read-Host "DefaultGateway"
    $domain_name=Read-Host "set the domain name"
    $dns=Read-Host "enter the DC01 IP address"
    New-NetIPAddress �IPAddress $ip -DefaultGateway $dg -PrefixLength 24 -InterfaceIndex (Get-NetAdapter).InterfaceIndex
    Set-DNSClientServerAddress �InterfaceIndex (Get-NetAdapter).InterfaceIndex �ServerAddresses $dns
    Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
    $secret=Read-Host "enter the domain password" -AsSecureString
    Install-ADDSDomainController -InstallDns -Credential (Get-Credential slipknot\Administrator) -DomainName $domain_name -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText $secret -Force)
    Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
    Install-WindowsFeature -Name 'DHCP' �IncludeManagementTools -IncludeAllSubFeature
    Add-DhcpServerInDC -DNSName $domain_name }

4 {$zone_name=read-host "enter the dns zone name"
   $zone_file=read-host "enter the dns zone backup file"
    Add-DnsServerPrimaryZone -Name $zone_name  -ZoneFile $zone_file}

5 {$CN=Read-Host "enter server name ("computer name")"
    $SR=Read-Host "enter start range (10.10.10.10)"
    $ER=Read-Host "enter end eange (10.10.10.10)"
    $name=Read-Host "enter scope name"
    $SM=Read-Host "enter subnet mask (255.255.255.0)"
    Add-DHCPServerv4Scope -StartRange $SR -ComputerName $CN -EndRange $ER -Name $name -SubnetMask $SM -State Active}

6 {$ip = Read-Host "enter scope ip (10.0.0.0)"
    $PSname = Read-Host "enter partner server name"
    $SSname = Read-Host "enter server scope owner"
    $LBP = Read-Host "enter a prasent to load balancent(1-100)"
    Add-DHCPServerv4Failover -ScopeId $ip -PartnerServer $PSname -ComputerName $SSname -LoadBalancePercent $LBP -AutoStateTransition $true }

7 { $name=Read-Host "enter the share name"
    $share=Read-Host "enter a share path for the folder\disc: F:\wow"
        New-SmbShare -Name $name  -Path $share }



8  {Install-WindowsFeature FS-SyncShareService -IncludeAllSubFeature
    $work_folder_name=Read-Host "enter the zone name (will be also the host name Alias and name)"
   Add-DnsServerResourceRecordCName �Name $work_folder_name �HostNameAlias $work_folder_name �ZoneName $work_folder_name}

9 { $DNSZone=Read-Host "enter the DNS Zone"
    $Filename=Read-Host "enter the File name"
    $CIMSession=Read-Host "on a remote DC? enter the Server Name"
    Export-DnsServerZone -Name $DNSZone -FileName $Filename -CimSession $CIMSession}

10 {$name=Read-Host "enter the user name"
    New-ADUser -Name $name -Accountpassword (Read-Host -AsSecureString "AccountPassword") -Enabled $true -PasswordNeverExpires $true}


11 { $group_name=Read-Host "enter the group name"
     $group_category=Read-Host "enter the group category (for Distribution enter 0, for Security enter 1)"
     $group_scope=read-host "enter the group scope tupe (for DomainLocal enter 0, for Global enter 1, for Universal enter 2)"
     New-ADGroup -Name $group_name -SamAccountName $group_name -GroupCategory $group_category -GroupScope $group_scope -DisplayName $group_name -Path "CN=Users,DC=slipknot,DC=main" -Description "Members of this group are in slipknot domain"
    }


12 {$username=Read-Host "Enter OU name"
    New-ADOrganizationalUnit -name $username -Path "DC=slipknot,DC=main"  -ProtectedFromAccidentalDeletion $False }

13 {$username=Read-Host "Enter the user name"
    New-Item -ItemType Directory -Name Profiles -Path C:\ -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Name Profile_$username -Path C:\Profiles\ -ErrorAction SilentlyContinue
    New-SmbShare -Path C:\Profiles\ -Name Profile -ErrorAction SilentlyContinue 
    Grant-SmbShareAccess -Name Profile -AccountName Everyone -AccessRight Full 
    Set-ADUser -Identity $username -ProfilePath \\dc01\profile\%username%
    Write-Host "new roaming profile for $username is set, at: C:\Profiles\%username%"
    }


14 {#$P = Get-Process -Name r*
#Write-Output $P
#in beta
$string = ","
    $out = Get-ADGroup -Filter 'GroupCategory -eq "Security" -and GroupScope -ne "DomainLocal"' -Properties * | select -property Name,Description,GroupCategory,GroupScope
    Write-Output $out | format-table
   
    $group_from_list=Read-Host "a list of all group in the AD, enter thdisarable group"
    $user_to_add=Read-Host "enter the users to add to the group"
    $users = $user_to_add + $string
    Add-ADGroupMember -Identity $group_from_list -Members $users}


15 {$root=Read-Host "enter folder path"
    Backup-GPO -Path $root -All}


16 {$root=Read-Host "enter folder path"
    $domain=Read-Host "enter domain name"
    $server_name=Read-Host "enter server name"
    Restore-GPO -All -Path $root -Domain $domain -Server $server_name

}
default {Write-Host ":( error is:"}
}
$continue = Read-Host "Continue? y/n"}

if ($continue -eq 'n') {
    write-host "thanks for using the system administrator tool" -BackgroundColor Cyan -ForegroundColor Black
}
