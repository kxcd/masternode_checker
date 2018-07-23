## masternode_checker
Checks the status of your DASH Masternodes and alerts you if there is problem


This bash shell script is designed to run from a cron periodically and it will check to see if you DASH Masternode(s) is running correctly, if it is not, it will send you an email and keep sending you emails at pre-defined rate until the problem is rectified.

This tool requires a working MTA on your VPS, probably not a default thing, so this guide will help you install a MTA also.

## Check you have a working MTA

Login to your VPS and try to send an email, in the command below replace the email address with your email.

    echo "Hello World!"|mailx -s Test EMAIL@example.com

You will almost certainly receive an error here and not get the email, then you need to install and config a MTA, but first you need a new email account for sending email, since you need to leave the email password on the VPS in plaintext, so for your security, I recommend creating a new gmail account specifically for sending these alert emails from.

## Create a Gmail account to send alerts from

The steps to do this are roughly detailed below.  Establish a new gmail email account (brand new). Added your 2FA and security to it, backup codes, etc until you are satifsified it is secure.  Next, create an application specific password in gmail, I had to search google for this, but it was easy to find steps on how to get this done, the purpose of this is two-fold 1) We don't want use the same pasword that can admin the entire gmail account, we want to limit the password for just being able to send email. 2) With 2FA on, your main password will not work.  Gmail will ask you which application the password is for, choose Email and it will display something like a 16 character password on the screen, record/save this password.



