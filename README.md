# Hello Bar 3.0

Made with love.

## Workflow

To add a new feature, make a branch of **edge**.  When ready to test, rebase your branch into **edge**.

When ready to deploy to production, merge **edge** into **master** and deploy.

## Provisioning a new Hello Bar server

0\. Once you've got the server's IP, log on.

1\. Add your own and your co-workers' public keys so that everyone can log in:

*On the server*, add additional SSH keys to `/home/hellobar/.ssh/authorized_keys`.

2\. Create the folders for deploy and disable the server's default Nginx config.

*On the server*, run the following script:

```bash
sudo su root - bash -c 'mkdir -p /mnt/deploy/shared/config; \
                        chown hellobar:staff -R /mnt/deploy; \
                        sudo service nginx stop; \
                        sudo update-ca-certificates; \
                        sudo update-rc.d nginx disable;'
```

3\. Copy the config files from a working server to the new one.

*On your local machine*, run the following script:

```bash
mkdir _temp; \
scp hellobar@184.72.141.214:/mnt/deploy/shared/config/*.yml _temp; \
scp _temp/* hellobar@<server_to_provision>:/mnt/deploy/shared/config; \
rm -r _temp
```
4\. Add the server's IP address to capistrano.

```ruby
# config/deploy/production.rb
...
server 'new-ip-address', user: 'hellobar', roles: %w{web}
...
```
