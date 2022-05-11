#requires -version 5
<#
.SYNOPSIS
  Simple CA setup to create a cert signing authority and subsequent server/client certs

.DESCRIPTION
  This script will create a local CA for self-signing of certificates. It aids the process of creating
  client auth certificates. It was inspired by the Barracuda Campus document that describes using XCA:
  https://campus.barracuda.com/product/campus/doc/28475773/how-to-create-certificates-with-xca

  XCA is a very cool program, however it may be overkill for someone who just needs to whip up a few 
  client certs

.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None>

.NOTES
  Version:        0.1
  Author:         Michael S Collins
  Creation Date:  2022-05-06
  Purpose/Change: Initial script development

.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [switch]
    $Help,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [switch]
    $clobber = $false,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $cakeyfile = './ca-key.pem',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $carootfile = './ca-root.pem',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $pass = 'abc123xyz',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $cn,    
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $san,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $c = 'US',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $st = 'California',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $l = 'Campbell',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $o = 'None',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $ou = 'None',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $email = 'None',
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [int]
    $bits = 2048,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [int]
    $serial = 1,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [int]
    $clientcerts = 1
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# CA config file to add extensions
$casslconfigfile = './ca-ssl.cnf'
$casslconfig = '#
[ req ]
x509_extensions = v3_ca

[ v3_ca ]
basicConstraints=critical,CA:true,pathlen:1
keyUsage=digitalSignature,keyAgreement,keyCertSign
'

# Server cert config file to add extensions
$svrsslconfigfile = './server-ssl.cnf'
$svrsslconfig = '#
[ req ]
req_extensions = req_ext

[ req_ext ]
basicConstraints=critical,CA:false
keyUsage=digitalSignature, keyAgreement, keyCertSign
subjectAltName=DNS:'

# Server cert config file to add extensions
$clientsslconfigfile = './client-ssl.cnf'
$clientsslconfig = '#
[ req ]
req_extensions = req_ext

[ req_ext ]
extendedKeyUsage=clientAuth
keyUsage=digitalSignature'



#-----------------------------------------------------------[Functions]------------------------------------------------------------

<#

Function <FunctionName> {
  Param ()

  Begin {
    Write-Host '<description of what is going on>...'
  }

  Process {
    Try {
      <code goes here>
    }

    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }
  }

  End {
    If ($?) {
      Write-Host 'Completed Successfully.'
      Write-Host ' '
    }
  }
}

#>
Function Print_Help {
    Param()
    
    Write-Host "        Simple CA setup script"
    Write-Host "    Supply the correct DNS, this script does the rest:"
    Write-Host ' '
    Write-Host "    Create all necessary private keys"
    Write-Host "    Create CA root cert"
    Write-Host "    Create server and client cert requests with proper extensions"
    Write-Host "    Sign server and client cert requests with CA root cert"
    Write-Host "    Output client and server certs in .pem and .pfx/.p12 formats"
    Write-Host ' '
    Write-Host "    If script is run subsequent times then user may start fresh or create new "
    Write-Host "    server and/or client certs signed by the existing CA"

    exit(1)
}

Function Validate_Openssl {
    Param ()
  
    Begin {
      Write-Host 'Checking for OpenSSL...'
    }
  
    Process {
      Try {
        $opensslver = openssl version
      }
  
      Catch {
        Write-Host -ForegroundColor Red "OpenSSL not found."
        Write-Host "Please install OpenSSL and ensure that 'openssl' is in the sytem path."
        Write-Host "Some have used Firedaemon with success:"
        Write-Host "https://www.firedaemon.com/download-firedaemon-openssl"
        Exit(1)
      }
    }
  
    End {
      If ($?) {
        Write-Host 'Found OpenSSL: ' + $opensslver -ForegroundColor Green
        Write-Host ' '
      }
    }
  }


  Function Create_CA_Root {
    Write-Host -NoNewLine "Generating private key for CA root... "
    openssl genrsa 2048 > $cakeyfile
    Write-Host -ForeGroundColor Green "Done"

    Write-Host -NoNewLine "Generating CA root cert... "
    openssl req -new -x509 -noenc -days 3650 -key $cakeyfile -subj "$rootsubj" -extensions $cacertextensions > $carootfile
    Write-Host -ForeGroundColor Green "Done"
}

Function Add_SSL_Config_Files {
    $casslconfig > $casslconfigfile
    # $cn isn't populated until runtime, so need to append to server config before writing to file
    $svrsslconfig = $svrsslconfig + $cn
    $svrsslconfig > $svrsslconfigfile
    $clientsslconfig > $clientsslconfigfile
}

Function Remove_SSL_Config_Files {
    Remove-Item $casslconfigfile
    Remove-Item $svrsslconfigfile
    Remove-Item $clientsslconfigfile
}

Function Create_CA_Root {
    Write-Host -NoNewLine "Generating" $bits.toString() "bit key for CA Root..."
    openssl genrsa $bits > ca-key.pem
    Write-Host -ForeGroundColor Green "Done"
    Write-Host -NoNewLine "Generating CA root certificate..."
    openssl req -new -x509 -noenc -days 3650 -key "$cakeyfile" -subj "$rootsubj" -config "$casslconfigfile" > $carootfile
    Write-Host -ForeGroundColor Green "Done"
}

Function Create_Server_Cert_Key_Pair {
    Write-Host -NoNewLine "Generating" $bits.toString() "bit key for server cert..."
    openssl genrsa $bits > server-key.pem
    Write-Host -ForeGroundColor Green "Done"
    Write-Host -NoNewLine "Generating CSR for server..."
    openssl req -new -noenc -key server-key.pem -subj "$subj" -config $svrsslconfigfile > ./server-csr.pem
    Write-Host -ForeGroundColor Green "Done"
    Write-Host "Signing server certificate with CA..."
    openssl x509 -req -days 3650 -in .\server-csr.pem -CA $carootfile -CAkey $cakeyfile -CAcreateserial -out server-crt.pem -extfile $svrsslconfigfile -extensions req_ext
    Write-Host -ForegroundColor Green "Done signing server certificate"
    Write-Host -NoNewline "Creating .pfx file for server certificate and key..."
    openssl pkcs12 -export -out ./server.pfx -inkey ./server-key.pem -in ./server-crt.pem -certfile $carootfile -passout pass:$pass
    Write-Host "Done" -ForegroundColor Green
}

Function Create_Client_Cert_Key_Pair {
    Write-Host -NoNewLine "Generating" $bits.toString() "bit key for client cert..."
    $clientkeyfile = "./client-{0:D4}-key.pem" -f $serial
    $clientcsrfile = "./client-{0:D4}-csr.pem" -f $serial
    $clientcrtfile = "./client-{0:D4}-crt.pem" -f $serial
    $clientpfxfile = "./client-{0:D4}.pfx" -f $serial
    openssl genrsa $bits > $clientkeyfile
    Write-Host -ForeGroundColor Green "Done"
    Write-Host -NoNewLine "Generating CSR for client $serial..."
    openssl req -new -noenc -key $clientkeyfile -subj "$subj" -config $clientsslconfigfile > $clientcsrfile
    Write-Host -ForeGroundColor Green "Done"
    Write-Host "Signing client certificate with CA..."
    openssl x509 -req -days 3650 -in $clientcsrfile -CA $carootfile -CAkey $cakeyfile -CAcreateserial -out $clientcrtfile -extfile $clientsslconfigfile -extensions req_ext
    Write-Host -ForeGroundColor Green "Done signing client $serial certificate"
    Write-Host -NoNewline "Creating .pfx file for client $serial certificate and key..."
    openssl pkcs12 -export -out $clientpfxfile -inkey $clientkeyfile -in $clientcrtfile -certfile $carootfile -passout pass:$pass
    Write-Host "Done" -ForegroundColor Green

}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Script Execution goes here
if ( $Help ) {
    Print_Help
}

Validate_Openssl

<#

$rootsubj="/C=US/ST=California/L=Clovis/O=None/OU=None/CN=collins.local"
openssl genrsa 2048 > ca-key.pem
## Need syntax to set the extensions and key usage!
openssl req -new -x509 -noenc -days 3650 -key .\ca-key.pem -subj "$rootsubj" > ca-cert.pem
$subj="/C=US/ST=California/L=Clovis/O=None/OU=None/CN=vpn.collins.local"
openssl genrsa 2048 > server-key.pem
openssl req -new -noenc -key .\server-key.pem -out server-csr.pem -subj "$subj"
openssl genrsa 2048 > client-key.pem
openssl req -new -noenc -key .\client-key.pem -out client-csr.pem -subj "$subj"
#>
if ( $cn -eq '' ) {
    Write-Host "Please designate the Common Name (cn) for these certificates. (<enter> = my.vpn.local)"
    $cn = Read-Host
    if ( $cn -eq '' ) {
        $cn = 'my.vpn.local'
    }
}
$rootsubj="/C=$c/ST=$st/L=$l/O=$o/OU=$ou/CN=$cn CA"
Write-Host "Using subject: $rootsubj for root CA certificate"
$subj="/C=$c/ST=$st/L=$l/O=$o/OU=$ou/CN=$cn"
Write-Host "Using subject: $subj for server and client certificates"

<#
$clientcsrfile = "./client-{0:D4}-csr.pem" -f $serial
if ( Test-Path $clientcsrfile ) {
    Write-Host "Client CSR file $clientcsrfile already exists. Please specify a different serial number." -ForegroundColor Yellow
    exit(1)
}
#>

$clientcrtfile = "./client-{0:D4}-crt.pem" -f $serial
if ( Test-Path $clientcrtfile ) {
  Write-Host "Client cert file $clientcrtfile already exists. Please specify a different serial number." -ForegroundColor Yellow
  exit(1)
}

$cakeyfile_exists = Test-Path -Path $cakeyfile
$carootfile_exists = Test-Path -Path $carootfile
if ( $cakeyfile_exists -and $carootfile_exists -and $serial -gt 1) {
    for ( $i=0; $i -lt $clientcerts; $i++ ) {
        Create_Client_Cert_Key_Pair
        $serial = $serial + 1
    }
    exit(0)
} elseif ( $cakeyfile_exists -and $carootfile_exists -and $clobber -eq $false ) {
  Write-Host -ForeGroundColor Yellow "`nExisting CA root cert and key found!"
  Write-Host "How would you like to proceed?"
  Write-Host "1 = Erase existing CA, server, client certs/keys and start from scratch"
  Write-Host "Any other input = Generate a new client cert/key with existing CA"
  Write-Host ' '
  $sel = Read-Host "Make selection"

  if ( $sel -ne '1' ) {
      Create_Client_Cert_Key_Pair
      exit(0)
  }
}

# Add a temporary openssl config file
Add_SSL_Config_Files

# Create CA Root Cert and Key 
Create_CA_Root

# Create server key and cert
Create_Server_Cert_Key_Pair

# Create client keys and certs
for ( $i=0; $i -lt $clientcerts; $i++ ) {
    Create_Client_Cert_Key_Pair
    $serial = $serial + 1
}

# Remove temporary openssl config file
#Remove_SSL_Config_Files

