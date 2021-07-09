#!/bin/bash

# For testing:
# rm -rf nextcloud-snap
# git clone --branch prettyurl https://github.com/nextcloud/nextcloud-snap.git
# cd nextcloud-snap

# Get the correct tar file from the branch itself
NC_DOMAIN="$(grep 'https://download.nextcloud.com/server' ./snap/snapcraft.yaml | grep -oP 'https://.*')"

# Download the tar file
curl -fL "$NC_DOMAIN" -o /tmp/ncpackage.tar.bz2

# Extract the archive
mkdir -p /tmp/nc
tar -xjf /tmp/ncpackage.tar.bz2 -C /tmp/nc

# Test if the needed file exists
if ! [ -f /tmp/nc/nextcloud/lib/private/Setup.php ]
then
    echo "The Setup couldn't get extracted."
    exit 1
fi

# Alway create a new htaccess file
rm -f ./src/apache/conf/.htaccess

# Get content of the updateHtaccess function and store it in a Variable called updateHtaccess
updateHtaccess="$(sed -n "/function updateHtaccess/,/function/p" /tmp/nc/nextcloud/lib/private/Setup.php)"

# Get all needed lines (containing the content variable)
updateHtaccess="$(echo "$updateHtaccess" | grep '$content =\|$content \.=')"

# Create file with final prettyurl config
echo "# Retreived from $NC_DOMAIN" >> /tmp/htaccess.conf
echo "$updateHtaccess" >> /tmp/htaccess.conf

# Remove comment line
sed -i '/DO NOT CHANGE ANYTHING ABOVE THIS LINE/d' /tmp/htaccess.conf

# Edit file to be valid
sed -i 's|.*"\\n||' /tmp/htaccess.conf
sed -i 's|;$||' /tmp/htaccess.conf
sed -i 's|"$||' /tmp/htaccess.conf
sed -i 's|\\\\|\\|g' /tmp/htaccess.conf

# Overwrite Webroot config
sed -i 's|ErrorDocument 403.*|ErrorDocument 403 \${WEBROOT}/|' /tmp/htaccess.conf
sed -i 's|ErrorDocument 404.*|ErrorDocument 404 \${WEBROOT}/|' /tmp/htaccess.conf

# Overwrite Rewritebase config
sed -i 's|RewriteBase.*|RewriteBase \${REWRITEBASE}|' /tmp/htaccess.conf

# Add the new config to the file
cat /tmp/htaccess.conf >> ./src/apache/conf/.htaccess
