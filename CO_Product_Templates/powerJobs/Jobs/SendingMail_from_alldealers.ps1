
##__SenfingInformingMail__AllMailDealers

#SendMail -To $Global:MailRecipients -Subject "Alert" -HTMLBody $message -Process $global:process -AppendDetails
$from = "jordi.fabregat.domenech@coolorange.com"
#$to = "jordi.fabregat.domenech@coolorange.com"
$to = "mail.publi.fd@gmail.com"
$subject = "Released test"
#$subject = "Released $($file.Name)"
#$body = "The $($file.Name) has been released by $($userName) and archived to $($archiveFolder). Attached archived pdf file."
$body = "The  has been released by  and archived to. Attached archived pdf file."
$smtp = "coolorange-com.mail.eo.outlook.com"
$passwd = ConvertTo-SecureString -AsPlainText "correu.brossa.6" -Force
$cred = new-object Management.Automation.PSCredential $from, $passwd
$sendattachment = $False
Send-MailMessage -To $to -From $from -Subject $subject -Body $body -SmtpServer $smtp -Credential $cred 