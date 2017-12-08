Class DNSEntry {
    [string]$name
    [string]$ipAddress
    DNSEntry($name, $ipAddress) {
        $this.name = $name
        $this.ipAddress =$ipAddress
    }
}

Class SRVDNSEntry:DNSEntry {
    [string]$service
    [string]$protocol
    [int]$priority = 0
    [int]$weigth = 0
    [int]$portNumber
    SRVDNSEntry($name,$ipAddress,$service,$protocol,$portNumber):base($name,$ipAddress) {
        $this.service = $service
        $this.protocol = $protocol
        $this.portNumber = $portNumber
    }
}

New-Object SRVDNSEntry 1,2,3,4,5
