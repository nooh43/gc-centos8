#!/bin/bash
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| CentOS8 Initialization - WP STACK
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| This script installs wordpress on lamp with ssl
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Version : V 0.0.2
#| Author  : Nasser Alhumood
#| .-.    . . .-.-.
#| |.|.-.-|-.-|-`-..-,.-.. .
#| `-``-`-'-' ' `-'`'-'   `
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#

#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Preparation stage
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Desciption   : In this stage we will update the
#| system then proceed by installing LAMP packages and
#| mod_ssl. 
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Environment  : update, install, firewall-cmd, systemctl, mv, chmod
#| Packages     : php-mysqlnd, php-fpm, mariadb-server, httpd, tar, curl, php-json, mod_ssl, certbot(curl)
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
echo -ne "Preparation stage           [\e[1;30;1;1;47min progress\e[0m]\r"
{
    # Updating the system
    sudo dnf -y update
    # Instaling LAMP packages and mod_ssl
    sudo dnf -y install php-mysqlnd php-fpm mariadb-server httpd tar curl php-json mod_ssl
    # Opening port 80 and 443 on the firewall 
    sudo firewall-cmd --permanent --zone=public --add-service=http 
    sudo firewall-cmd --permanent --zone=public --add-service=https
    sudo firewall-cmd --reload
    # Downloading certbot, moving it to its directory, and giving it permission
    sudo curl -O https://dl.eff.org/certbot-auto
    sudo mv certbot-auto /usr/local/bin/certbot-auto
    sudo chmod 0755 /usr/local/bin/certbot-auto
    # Running and enabling httpd and mysql on the system
    sudo systemctl start mariadb
    sudo systemctl start httpd
    sudo systemctl enable mariadb
    sudo systemctl enable httpd
} &> /dev/null
echo -ne "SYSTEM UPDATE               [\e[1;37;1;1;42m   +done   \e[0m]"
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#

#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Action stage
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Desciption   : In this stage we will ask the user
#| for his domain name. Then we will create a template
#| for his virtual host and move it to the right
#| directory. After that we will create a folder for
#| his wordpress and give it the right permissions.
#| Then, we will proceed by installing Let's Encrypte
#| ssl certificate. When all of this is done, we will
#| get the latest version of wordpress and extract it to
#| the main wordpress folder.
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Environment  : cat, mv, mkdir, chown, chcon, systemctl, tar, cp, rm
#| Packages     : wordpress(curl)
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
    # Ask the user if he wants to add a virtualhost
    read -p "Would you like to create a wordpress website? [y/N] "
    # If the user types Y or y ( basically answers with yes )
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Ask the user for his domain name
        echo -n "what is your domain name (without www): "
        # Store the domain name in variable DOMAINNAME
        read DOMAINNAME
        # Write the data of the virtual host into the template file
cat <<EOM >apps/wordpress/www.$DOMAINNAME.conf
<VirtualHost *:80>
  ServerName $DOMAINNAME
  ServerAlias www.$DOMAINNAME
  DocumentRoot /var/www/www.$DOMAINNAME
  
  <Directory /var/www/www.$DOMAINNAME>
      Options -Indexes +FollowSymLinks
      AllowOverride All
  </Directory>

  ErrorLog /var/log/httpd/www.$DOMAINNAME-error.log
  CustomLog /var/log/httpd/www.$DOMAINNAME-access.log combined
</VirtualHost>
EOM
        # Move the template to its location
        sudo mv apps/wordpress/www.$DOMAINNAME.conf /etc/httpd/conf.d/www.$DOMAINNAME.conf
        # Create a folder for the wordpress space
        sudo mkdir -p /var/www/www.$DOMAINNAME
        # Give the wordpress space its Permissions
        sudo chown -R apache:apache /var/www/www.$DOMAINNAME
        sudo chcon -t httpd_sys_rw_content_t /var/www/www.$DOMAINNAME -R
        # Restart httpd
        systemctl restart httpd
        # Print Done
        echo -e "VIRTUAL HOST CREATION       [\e[1;37;1;1;42m   +done   \e[0m]"
        echo
        # Generate and install Let’s Encrypt certificate
        sudo /usr/local/bin/certbot-auto --apache
        # Add a command-line to renew the ssl certificate each 90 days
        sudo echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null
        # Print Done
        echo -e "SSL CERTIFICATE INSTALLATION[\e[1;37;1;1;42m   +done   \e[0m]"
        echo
        # Download wordpress
        sudo curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz
        # Extract it
        sudo tar xf wordpress.tar.gz
        # Copy everything from the wordpress file to the main wordpress space
        sudo cp -r wordpress/* /var/www/www.$DOMAINNAME
        # Remove the file downloaded
        sudo rm -r wordpress
        # Give the wordpress space its Permissions
        sudo chown -R apache:apache /var/www/www.$DOMAINNAME
        sudo chcon -t httpd_sys_rw_content_t /var/www/www.$DOMAINNAME -R
        # Print Done
        echo -e "PREPARING WORDPRESS         [\e[1;37;1;1;42m   +done   \e[0m]"
        echo
    fi
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#

#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Finishing Stage
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Desciption   : In this stage we will instruct the
#| user on what to do next and how to proceed with his
#| stack installation.
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
#| Environment  : cat
#| Packages     : (NONE)
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#
    # Print Congrats
    echo
    echo
    echo
    echo -e "\e[31;1m  Sounds like we are done, Everything is set.  \e[0m"
    echo -e "\e[31;1m  However there are a few things you need to do.  \e[0m"
    # MySQL instruction
    echo
    echo
    echo
    echo -e "\e[31;1m  Lets start with maintaining MySQL:  \e[0m"
    echo -e "\e[31;1m  1- Run this command to secure MySQL and set its root password:  \e[0m"
    echo -e "\e[31;1m  sudo mysql_secure_installation  \e[0m"
    echo -e "\e[31;1m  2- Create a new database with name wordpress and user admin and password pass:  \e[0m"
    cat apps/wordpress/HowToDatabase.txt
    # Wordpress instruction
    echo
    echo
    echo
    echo -e "\e[31;1m  Then go to your website and proceed with the installation.  \e[0m"
    echo "Thank you for using this application"
#|=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-#