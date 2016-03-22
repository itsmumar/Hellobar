# Hello Bar 3.0
this is a test

Made with love.

## Development

Bundle install all the gems

`bundle install`

Setup your database.yml file

`cp config/database.yml.example config/database.yml`

Setup the settings.yml file

`cp config/settings.yml.example config/settings.yml`

Let rake setup and migrate all your databases

`rake db:setup`

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

**Production:**
https://hellobar.com
user: prodtest@polymathic.me
pword: password
site: horse.bike


## Running Hello Bar via Docker

This section assumes that you are using the [Docker Toolbox](https://www.docker.com/products/docker-toolbox) or have the knowledge to set up the various components on your own.

### 1. Update your database.yml file

Your `database.yml` file will need to be updated to reflect the connection information for the database container. The username, password, host, and port should match the following example:

```yml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password: root
  host: mysql
  port: 3306
```

### 2. Build and start the containers

Once your `database.yml` and `settings.yml` files are how you like them, run the following commands in a `Docker Quickstart Terminal`:

```
docker-compose build
docker-compose up
```

This will build your containers and start them up. The first time you run `docker-compose build` it will likely take a while to complete as it updates various libraries and installs the required gems.

`docker-compose up` will then start the containers

### 3. Database setup / one-off commands

If you need to run one-off commands like `rake db:setup`, you can do so using `docker exec <CONTAINER NAME> rake db:setup`

To find the name of the containers that docker-compose has built, use `docker ps` to see output akin to the following:

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
71a3eaa56507        hellobarnew_web     "bundle exec thin sta"   19 minutes ago      Up About a minute   0.0.0.0:80->3000/tcp   hellobarnew_web_1
ecb9c271c139        mysql               "/entrypoint.sh mysql"   19 minutes ago      Up About a minute   3306/tcp               hellobarnew_db_1
```

In the above example, `hellobarnew_web_1` is the name of the web container.

### 4. Accessing the dockerized Hello Bar in your browser

`docker-compose up` will automatically set up the app to listen on port 80. You can get the IP address of Docker's VM using `docker-machine ip` on the command line.

In order for the Google OAuth to work properly, you'll need to update your `/etc/hosts` file to map `local.hellobar.com` to your VM's IP address. For example, if your VM IP is `192.168.99.100`, you'll add the following line to `/etc/hosts`

```
192.168.99.100  local.hellobar.com
```

Navigating to [local.hellobar.com](http://local.hellobar.com) will then point to your local dockerized copy of Hello Bar


### 5. Enabling SSH within the container

If you need to use SSH from within the web container (e.g. deploying via capistrano), you can use the following commands to add your SSH keys and known hosts to the dockerized environment:

```bash
$ docker run --rm --volumes-from=hellobarnew_agent_1 -v ~/.ssh:/ssh -it whilp/ssh-agent:latest ssh-add /ssh/id_rsa
$ docker run --rm --volumes-from=hellobarnew_agent_1 -v ~/.ssh:/ssh -it whilp/ssh-agent:latest cp /ssh/known_hosts /root/.ssh/known_hosts
```

You'll want to substitute your private key name and agent container (the default is `hellobarnew_agent_1`)
