# Hello Bar 3.0

Made with love.

## Workflow

To add a new feature, make a branch of **master**.  When ready to test, rebase your branch into **master**.

When ready to deploy to production, merge **master** into **production** and use capistrano to deploy the **production** branch.

```BRANCH=production cap production deploy```

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

## Testing generated scripts

### Manually in Development

There is a sinatra app in `test_site`.

#### Defaults
Run `rake test_site:generate` to generate `test_site/public/test.html`
using the last site created.

Run `rake test_site:run` to start the Sinatra server and navigate to
`localhost:4567`

By default this will use the last site created to generate the js.

You can explicitly pass a site id as well:

```
rake test_site:generate[2]
```


#### Options

To generate a site html file at an arbitary location:

```
rake test_site:file[2,'/Users/hb/index.html']
```

The above method is used by the capybara integration tests.

All of these rake tasks use the `lib/SiteGenerator.rb` class as well as
an `HbTestSite` class defined within the rake task itself.

### Automated (integration) tests

Integration tests run in the `spec/features` directory.  They use the
`lib/SiteGenerator` to create an html file in `public/integration`.  The
file name is a random hex.

Capybara navigates to the public html file in order to test interations.

To test the content of the iframe use `within_frame`.

To test adding or removing the iframe use
`page.driver.browser.frame_focus`.

Watch out for animations and other asyncronous or delayed interactions.
You may need to fiddle with the `Capybara.default_wait_time` in
`spec/spec_helper`.

**Keep in mind you will need to have `capybara-webkit` compiled with QT5(QT 4.8 will break tests)**

You can do so this way:

```
gem uninstall --all capybara-webkit
brew remove qt
brew install qt5
brew linkapps qt5 # optional?
brew link --force qt5
gem install capybara-webkit
```

## Live testing/QA info

Test site for both edge/staging: http://tjacobs3.github.io/hellobar_testing/

**Edge:**  
http://edge.hellobar.com/  
user: edge-test@polymathic.me  
pword: password  
site: edge-testing.com

**Staging:**  
http://staging.hellobar.com/  
user: staging-test@polymathic.me  
pword: password  
site: gewgle.com
