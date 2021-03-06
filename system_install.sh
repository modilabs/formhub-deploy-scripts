# network connection with DNS required
ping -c 1 google.com 2>&1 | grep unknown > /dev/null
if [ $? -eq 0 ]
then
    echo Network connection not found. Please connect and try again
    exit 1
else
    echo Network connection found.  Installing...
fi

# install formhub system dependencies
sudo apt-get -qq update
sudo apt-get -qq install curl
sudo apt-get -qq install git-core
sudo apt-get -qq install python-dev
sudo apt-get -qq install python-setuptools
sudo apt-get -qq install default-jre
sudo apt-get -qq install dhcp3-server
sudo apt-get -qq install openssh-server

# install python pip installation tool
sudo easy_install pip

# clone shell scripts repo?
cd ~
sudo -u formhub git clone https://github.com/modilabs/formhub-deploy-scripts.git bin
cd bin
sudo chown -R formhub:formhub * .
sudo chmod u+x .
cd ~

# add bash profile settings
#cat ~/bin/bash_profile_extender.sh >> ~/.bashrc
#source ~/.bashrc
cat "source ~/bin/bash_profile_extender.sh" >> /home/formhub/.bashrc

# create a directory for formhub
mkdir site
cd site
sudo chown formhub:formhub .

# clone git repo from 
sudo -u formhub git clone https://github.com/modilabs/formhub.git -b local-node

# change into site directory
cd formhub

# install site specific requirements
sudo pip install -r requirements.pip

# set permissions and bootstrap
sudo chown -R formhub:formhub * .
sudo -u formhub python manage.py bootstrap -v0

# sudo privileges to run server in screen
echo 'formhub ALL=(ALL) NOPASSWD: /home/formhub/bin/run_server.sh' | sudo tee -a /etc/sudoers > /dev/null

# install reverse ssh cron
sudo -u formhub echo '*/3 * * * * /bin/bash /home/formhub/bin/reverse_ssh.sh >/dev/null 2>&1' | crontab
sudo service cron restart

# start server on boot
sudo cp /home/formhub/bin/formhub_initd /etc/init.d/formhub
sudo chmod u+x /etc/init.d/formhub
sudo chown formhub:formhub /etc/init.d/formhub
sudo update-rc.d formhub start 20 2 3 4 5 . stop 20 0 1 6 .

# copy dhcpd conf
sudo cp /home/formhub/bin/dhcpd.conf /etc/dhcp3/dhcpd.conf

# create sym links
sudo ln -s /home/formhub/bin/start_server.sh ~/Desktop/start-server
sudo ln -s /home/formhub/bin/stop_server.sh ~/Desktop/stop-server
sudo ln -s /home/formhub/bin/start_adhoc.sh ~/Desktop/start-adhoc-network
sudo ln -s /home/formhub/bin/stop_adhoc.sh ~/Desktop/stop-adhoc-network
sudo chown -h formhub:formhub ~/Desktop/*

# start server now
sudo /etc/init.d/formhub start

# confirm install
echo
if [ -d ~/site/formhub ] && [ -f /etc/init.d/formhub ]
then
    echo Installation succeeded.
    echo The server is now running at http://localhost
    echo
    echo To start the wireless network use click the links on your desktop,
    echo then click "Run in Terminal" in the window that appears.
else
    echo Installation failed.
fi

