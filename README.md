## masternode_checker
Checks the status of your DASH Masternodes and alerts you if there is problem


This bash shell script is designed to run from a cron periodically and it will check to see if your DASH Masternode(s) is/are running correctly, if it is not, it will send you an email and keep sending you emails at a pre-defined rate until the problem is rectified.

This tool requires a working a MTA on your VPS, probably not a default thing, so this guide will help you install an MTA also.

## Check you have a working MTA

Login to your VPS and try to send an email, in the command below replace the email address with your email.

    echo "Hello World!"|mailx -s Test EMAIL@example.com

You will almost certainly receive an error here and not get the email, then you need to install and configure an MTA, but first you need a new email account for sending email, since you need to leave the email password on the VPS in plaintext, so for your security, I recommend creating a new gmail account specifically for sending these alert emails from.

## Create a Gmail account to send alerts from

The steps to do this are roughly detailed below.  Establish a new gmail account (brand new). Added your 2FA and security to it, backup codes, etc until you are satifsified it is secure.  Next, create an application specific password in gmail, I had to search google for this, but it was easy to find steps on how to get this done, the purpose of this is two-fold
1) We don't want use the same pasword that can administer the entire gmail account, we want to limit the password for just being able to send email.
2) With 2FA on, your main password will not work from the VPS.

Gmail will ask you which application the password is for, choose Email and it will display something like a 16 character password on the screen, record/save this password.

## Install and Configure a simple MTA

For this I followed the guide over at https://www.sbprojects.net/projects/raspberrypi/exim4.php with great success.  Read it carefully and follow the left hand side workflow for Exim4.  Very terse details posted below in case that site goes dead.


    sudo apt-get install exim4
    sudo dpkg-reconfigure exim4-config
    sudo apt install s-nail
 Now you need to answer some questions. Don't worry I'll give you the answers to those questions.

   The first screen asks you what type of mail server you need. Select the second option: "mail sent by smarthost; received via SMTP or fetchmail"
   
    The next question asks for the system mail name: Set to same as hostname (your_hostname)
    
    Now it asks you what IP addresses should be allowed to use the server. Leave as is (127.0.0.1 ; ::1)
    
    Other destinations for which mail is accepted: hostname
    
    Machines to relay mail for: Leave blank.
    
    IP address or host name of outgoing smarthost: Replace by: smtp.gmail.com::587
    
    Hide local mail name in outgoing mail: Select: No
    
    Keep number of DNS-queries minimal: Select: No
    
    Delivery method for local mail: Select: "Mbox"
    
    Split configuration into small files: Select: No
    
    Root and postmaster mail recipient: Enter: <your user>

After answering all these questions exim4 will restart and we're halfway home.

Now you'll have to enter your account details. As root, edit the file /etc/exim4/passwd.client and add the next three lines at the end of the file. 

    sudo nano /etc/exim4/passwd.client
Make sure the below is added and replace with your email address and password

    gmail-smtp.l.google.com:YOU@gmail.com:PASSWORD
    *.google.com:YOU@gmail.com:PASSWORD
    smtp.gmail.com:YOU@gmail.com:PASSWORD

Next,

    sudo update-exim4.conf
    sudo service exim4 restart


and,


    sudo nano /etc/aliases

update the below lines to add your user and your email address

    root: <user>
    <user>: youremail@example.com

Finally,

    sudo newaliases

## Test your MTA

At this point you should have a working MTA, it is prudent to test it now.  In the command below replace the email address with your email.

    echo "Hello World!"|mailx -s Test EMAIL@example.com

You should get the email, continue on, otherwise resolve the issue before proceeding.


## Install and configure this script and setup up cron

Now it is time to install this script and edit it to add your MNs to it.  Login to your VPS as the user that runs the dashd daemon.

    sudo apt install netcat jq
    cd /tmp
    git clone https://github.com/kxcd/masternode_checker
    mkdir ~/bin
    cp masternode_checker/masternode_checker.sh ~/bin
    chmod a+x ~/bin/masternode_checker.sh

The script is now in the right place, but you need to edit it to add your details in there.  Use nano or vi.

    nano ~/bin/masternode_checker.sh

Read the comments, the first thing to change is the EMAIL= variable, add your receiving email address here, ie the one you want to get notified on.  Next edit the MASTERNODES= variable and replace the 3 example MNs with your MN(s), leave a space between each and do not line break the variable, it is OK if it wraps, but don't press ENTER.

Now edit the cron to schedule the job.

    crontab -e

Make sure you have the below lines,

    SHELL=/bin/bash
    PATH=/usr/sbin:/usr/bin:/sbin:/bin:<another path that goes to the directory where dash-cli is>

Update the PATH variable as above, next add a line at the end of the crontab, like so

    5,10,15,20,25,30,35,40,45,55 * * * * ~/bin/masternode_checker.sh

Save the crontab and you should be working.  To test everything is actually working, edit the masternode_checker.sh `nano ~/bin/masternode_checker.sh` and mis-type your MN address, save and wait a few mins, you should get an email, if you do revert, the change you are now done, if not troubleshoot this guide.

if you have more than one MN it is strongly recommended to put this on ALL the VPS servers, there is a very good reason for this, if the VPS itself goes down that VPS cannot send the email, but your other VPS might still be up and notify you that a VPS went down, IMO that is what makes this script so powerful.
