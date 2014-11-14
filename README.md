# Hello Bar 3.0

Made with love.

## Provisioning a new Hello Bar server

1. Once you've got the server's IP, log on.
2. Create the folders for deploy and disable the server's default Nginx config.

*On the server*, run the following script:

```bash
sudo su root - bash -c 'mkdir -p /mnt/deploy/shared/config; \
                        chown hellobar:staff -R /mnt/deploy; \
                        sudo service nginx stop; \
                        sudo update-ca-certificates; \
                        sudo update-rc.d nginx disable;'
```

3. Copy the config files from a working server to the new one.

*On your local machine*, run the following script:

```bash
mkdir _temp; \
scp hellobar@184.72.141.214:/mnt/deploy/shared/config/*.yml _temp; \
scp _temp/* hellobar@<server_to_provision>:/mnt/deploy/shared/config; \
rm -r _temp
```
4. Add the server's IP address to capistrano.

# config/deploy/production.rb

```ruby
...
server 'new-ip-address', user: 'hellobar', roles: %w{web}
...
```
