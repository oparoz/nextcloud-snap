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

# Get content of the updateHtaccess function and store it in a Variable called updateHtaccess
updateHtaccess="$(sed -n "/function updateHtaccess/,/function/p" /tmp/nc/nextcloud/lib/private/Setup.php)"

# Get all needed lines (containing the content variable)
updateHtaccess="$(echo "$updateHtaccess" | grep '$content =\|$content \.=')"

# Create file with final prettyurl config
echo '#Prettyurl-start' > /tmp/apache.conf
echo "# Retreived from $NC_DOMAIN" >> /tmp/apache.conf
echo "$updateHtaccess" >> /tmp/apache.conf

# Remove comment line
sed -i '/DO NOT CHANGE ANYTHING ABOVE THIS LINE/d' /tmp/apache.conf

# Edit file to be valid
sed -i 's|.*"\\n||' /tmp/apache.conf
sed -i 's|;$||' /tmp/apache.conf
sed -i 's|"$||' /tmp/apache.conf
sed -i 's|\\\\|\\|' /tmp/apache.conf

# Overwrite Webroot config
sed -i 's|ErrorDocument 403.*|ErrorDocument 403 \${WEBROOT}/|' /tmp/apache.conf
sed -i 's|ErrorDocument 404.*|ErrorDocument 404 \${WEBROOT}/|' /tmp/apache.conf

# Overwrite Rewritebase config
sed -i 's|RewriteBase.*|RewriteBase \${REWRITEBASE}|' /tmp/apache.conf

# Complete the file
echo '#Prettyurl-end' >> /tmp/apache.conf

# Remove current PrettyUrl config
sed -i "/^#Prettyurl-start/,/^#Prettyurl-end/d" ./src/apache/conf/httpd.conf

# Add the new config to the file
sed -i '/<IfDefine EnablePrettyurls>/r /tmp/apache.conf' ./src/apache/conf/httpd.conf