# Snappy Nextcloud

Nextcloud server packaged as a snap. It consists of:

- Nextcloud 21
- Apache 2.4
- PHP 7.4
- MySQL 8
- Redis 5.0
- mDNS for network discovery


## How to install

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-white.svg)](https://snapcraft.io/nextcloud)

There are a [number of releases available][1]. By default you'll get the newest
stable one, but you may be interested in others.


## How to use

After install, assuming you and the device on which it was installed are on the
same network, you should be able to reach the Nextcloud installation by visiting
`<hostname>.local` in your browser. If your hostname is `localhost` or
`localhost.localdomain`, like on an Ubuntu Core device, `nextcloud.local` will
be used instead.

Upon visiting the Nextcloud installation for the first time, you'll be prompted
for an admin username and password. After you provide that information you'll be
logged in and able to create users, install apps, and upload files.

Note that this snap includes a service that runs cron.php every 15 minutes,
which will automatically change the cron admin setting to Cron for you.


### Removable media

Also note that the interface providing the ability to access removable media is
not automatically connected upon install, so if you'd like to use external
storage (or otherwise use a device in `/media` or `/mnt` for data), you need to
give the snap permission to access removable media by connecting that
interface:

    $ sudo snap connect nextcloud:removable-media


### System monitoring

The System application requires a bit more access to the system than the snap
uses by default (e.g. the ability to monitor network hardware, etc.). If you'd
like to utilize those features, you'll need to connect the interface that
allows that kind of access:

    $ sudo snap connect nextcloud:network-observe


### Configuration

Beyond the typical Nextcloud configuration (either by using `nextcloud.occ` or
editing `/var/snap/nextcloud/current/nextcloud/config/config.php`), the snap
exposes extra configuration options via the `snap set` command.


#### HTTP/HTTPS port configuration

By default, the snap will listen on port 80. If you enable HTTPS, it will listen
on both 80 and 443, and HTTP traffic will be redirected to HTTPS. But perhaps
you're putting the snap behind a proxy of some kind, in which case you probably
want to change those ports.

If you'd like to change the HTTP port (say, to port 81), run:

    $ sudo snap set nextcloud ports.http=81

To change the HTTPS port (say, to port 444), run:

    $ sudo snap set nextcloud ports.https=444

Note that, assuming HTTPS is enabled, this will cause HTTP traffic to be
redirected to port 444. You can specify both of these simultaneously as well:

    $ sudo snap set nextcloud ports.http=81 ports.https=444

**Note:** Let's Encrypt will expect that Nextcloud is exposed on ports 80 and
443. If you change ports and _don't_ put Nextcloud behind a proxy such that
ports 80 and 443 are sent to Nextcloud for that domain name, Let's Encrypt will
be unable to verify ownership of your domain and will not grant certificates.

**Also note:** Nextcloud's automatic hostname detection can fail when behind
a proxy; you might notice it redirecting incorrectly. If this happens, override
the automatic detection (including the port if necessary), e.g.:

    $ sudo nextcloud.occ config:system:set overwritehost --value="example.com:81"


#### PHP Memory limit configuration

By default, PHP will use 128M as the memory limit. If you notice images not
getting previews generated, or errors about memory exhaustion in your Nextcloud
log, you may need to set this to a higher value.

If you'd like to set the memory limit to a higher value (say, 512M), run:

    $ sudo snap set nextcloud php.memory-limit=512M

To set it to be unlimited (not recommended), use -1:

    $ sudo snap set nextcloud php.memory-limit=-1


#### Cronjob interval configuration

By default the cronjob interval is 15 minutes.

To adjust it (say, 10 minutes) simply run:

    $ sudo snap set nextcloud nextcloud.cron-interval=10m

If you want to disable the cronjob completely, run:

    $ sudo snap set nextcloud nextcloud.cron-interval=-1

To reenable it again simply set the `nextcloud.cron-interval` snap variable to a value that isn't `-1`

#### HTTP compression configuration

If desired the snap can use HTTP compression by running:

    $ sudo snap set nextcloud http.compression=true

To disable it again just run:

    $ sudo snap set nextcloud http.compression=false

#### Debug mode

By default, the snap installs itself in production mode, which prevents Apache
and PHP from providing any detailed version or library information in the HTTP
headers and error pages. Debug mode can be enabled with:

    $ sudo snap set nextcloud mode=debug

"debug" and "production" are the only valid modes.


### Included CLI utilities

There are a few CLI utilities included:

- `nextcloud.occ`:
    - Nextcloud's `occ` configuration tool. You can always edit the config file
      directly (`/var/snap/nextcloud/current/nextcloud/config/config.php`) but
      the configuration tool provides a CLI interface for it. See
      `nextcloud.occ -h` for more information. Note that it requires `sudo`.
- `nextcloud.mysql-client`:
    - MySQL client preconfigured to communicate with Nextcloud MySQL server.
      This may be useful in case you need to migrate Nextcloud installations.
      Note that it requires `sudo`.
- `nextcloud.mysqldump`:
    - Dump Nextcloud database to stdout. You should probaby redirect its output
      to a file. Note that it requires `sudo`.
- `nextcloud.enable-https`:
    - Enable HTTPS via self-signed certificates, Let's Encrypt, or custom
      certificates. HTTP will redirect to HTTPS. Non-custom certificates will
      automatically be kept up-to-date. See `nextcloud.enable-https -h` for more
      information. Note that it requires `sudo`.
- `nextcloud.disable-https`:
    - Disable HTTPS (does not remove certificates). Note that it requires
      `sudo`.
- `nextcloud.manual-install`:
    - Manually install Nextcloud instead of visiting it in your browser. This
      allows you to create the admin user via the CLI. Note that it requires
      `sudo`.
- `nextcloud.export`:
    - Export data suitable for migrating servers. By default this includes the
      Nextcloud database, configuration, and data. See `nextcloud.export -h` for
      more information. Note that it requires `sudo`.
- `nextcloud.import`:
    - Import data exported from another Nextcloud snap instance (via
      `nextcloud.export`). By default this imports the database, config, and
      data. See `nextcloud.import -h` for more information. Note that it
      requires `sudo`.


## Where is my stuff?

- `$SNAP_DATA` (`/var/snap/nextcloud/current/` by default)
    - Logs (Apache, PHP, MySQL, Redis, and Nextcloud logs)
    - Keys and certificates
    - MySQL database
    - Redis database
    - Nextcloud config
    - Any Nextcloud apps installed by the user
- `$SNAP_COMMON` (`/var/snap/nextcloud/common/` by default)
    - Nextcloud data


## Hacking

If you change something in the snap, build it, install it, and you can run a
suite of acceptance tests against it. The tests are written in ruby, using
capybara and rspec. To run the tests, you first need to install a few
dependencies:

    $ sudo apt install gcc g++ make qt5-default libqt5webkit5-dev ruby-dev zlib1g-dev
    $ sudo gem install bundle
    $ cd tests/
    $ bundle install

Additionally, if you do not have X configured, install the following for a
'fake' X server.

    $ sudo apt install xvfb

Make sure the snap has a user called "admin" with password "admin" (used for
login tests):

    $ sudo nextcloud.manual-install admin admin

And finally, run the tests:

    $ cd tests/
    $ rake test

[1]: https://github.com/nextcloud/nextcloud-snap/wiki/Release-strategy
