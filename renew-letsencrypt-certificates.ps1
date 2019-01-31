# renew-letsencrypt-certificates.ps1
#
# version 0.1 - graham.newland@gmsl.co.uk
#
# instructions:

$OPENSSL = "c:\scripts\openssl.exe"
$RDPFX = "c:\scripts\tmp.pfx"
$EXPPWD = "--REPLACE-THIS--"
$EXPPWDSEC = ConvertTo-SecureString -string $EXPPWD -force -AsPlainText
$oldCert=Get-PACertificate
$newCert=Submit-Renewal --DOMAIN-NAME--

if($newCert -and ($oldCert -ne $newCert)) {

   write-debug "Certificate has been renewed, updating IIS and RD"
   $newCert | Set-IISCertificate -SiteName 'Default Web Site'

   if($?){
        $thumbprint=$newCert.Thumbprint
        if($thumbprint) {

            write-debug Updating RDS...
            
            $OPENSSL pkcs12 -export -in $newCert.CertFile -inkey $newCert.KeyFile -out $RDPFX -passout pass:$EXPPWD

            set-rdCertificate -Role RDGateway -ImportPath $RDPFX -Password $EXPPWDSEC -force
            set-rdcertificate -Role RDWebAccess -ImportPath $RDPFX -Password $EXPPWDSEC -force
            set-rdcertificate -Role RDRedirector -ImportPath $RDPFX -Password $EXPPWDSEC -force
            set-rdcertificate -Role RDPublishing -ImportPath $RDPFX -Password $EXPPWDSEC -force

            Send-MailMessage -Subject "LetsEncrypt Certificate: UPDATED" -Body "The certificate for the --REPLACE-THIS-- Hosted environment has been updated on --REPLACE-THIS--. Please log onto --URL-- and ensure that you can launch applications!" -To --TO-- -From --FROM-- -SmtpServer --SMTP-- -UseSsl

            # now copy to RDS2 and RDSTEST
            copy-item $RDPFX \\--HOST--\c$\scripts\
            #copy-item $RDPFX \\--HOST--\c$\scripts\
            $EXPPWD | out-file \\--HOST--\c$\scripts\tmp.key
            #$EXPPWD | out-file \\--HOST--\c$\scripts\tmp.key

            # clean up
            # remove-item $RDPFX

        }
    }
}

