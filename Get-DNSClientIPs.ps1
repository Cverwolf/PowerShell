<#
.SYNOPSIS
This script parses DNS debug logs for private IP addresses

.DESCRIPTION
This script parses DNS debug logs for the private IP addresses that have made queries to the system
It will output a CSV called 'DNSClients.csv' in the current working directory 
containing the IP addresses and hit counts for each sorted descending by count.
The script will pass any public IP addresses, and will only look for inbound queries.
The path to the log file 'DNSlogPath' is the only required parameter

.PARAMETER DNSlogPath
Path to the DNS debug log file

.EXAMPLE
Parse DNS log on a remote system

Get-DNSClientIPs -DNSlogPath "\\DNSServer01\c$\WINDOWS\system32\dns\dns.log"

.NOTES
Uses function 'Test if an IP is in a private subnet' from the MS Script repository 
Thanks to 'HannovdM'
https://gallery.technet.microsoft.com/scriptcenter/a28770f4-8dac-4d66-9451-c0d2a4b8cf80
#>



Param ([Parameter(Mandatory=$true)]
[string]$DNSlogPath)

$DNSClients = @()


Function ConvertTo-BinaryIP( [String]$IP ) { 
 
  $IPAddress = [Net.IPAddress]::Parse($IP) 
 
  Return [String]::Join('.', 
    $( $IPAddress.GetAddressBytes() | %{ 
      [Convert]::ToString($_, 2).PadLeft(8, '0') } )) 
} 
 
 
Function IsPrivateNetwork( [String]$IP)  
{ 
    If ($IP.Contains("/")) 
    { 
        $Temp = $IP.Split("/") 
        $IP = $Temp[0] 
    } 
   
    $BinaryIP = ConvertTo-BinaryIP $IP; $Private = $False 
   
    Switch -RegEx ($BinaryIP) 
    { 
        "^1111" { $Class = "E"; $SubnetBitMap = "1111" } 
        "^1110" { $Class = "D"; $SubnetBitMap = "1110" } 
        "^110"  { $Class = "C" 
                    If ($BinaryIP -Match "^11000000.10101000") { $Private = $True }  
                } 
        "^10"   { $Class = "B" 
                    If ($BinaryIP -Match "^10101100.0001") { $Private = $True } } 
        "^0"    { $Class = "A" 
                    If ($BinaryIP -Match "^00001010") { $Private = $True }  
                } 
    }    
    return $Private 
} 




Get-Content $DNSlogPath | where {$_ -match "Rcv " -and ($_ -match " Q " -or $_ -match " R Q ")} | foreach {
   $ClientIP = ($_ -split(" "))[8]

if (IsPrivateNetwork($ClientIP) -eq $true)
{

   $DNSClients += New-Object psobject -Property @{
     ClientIP = $ClientIP

}
   } 
} 

$DNSClients | Group-Object -Property ClientIP -NoElement | Sort-Object Count -Descending  | `
select count, @{Name="IP";Expression={$_.name}} | export-csv -nti ./DNSClients.csv
