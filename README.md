# Hello Bar 3.0

Made with love.

[![CircleCI](https://circleci.com/gh/Hello-bar/hellobar_new.svg?style=svg&circle-token=a40215cbc1e8ef0718fced860063731f53206e73)](https://circleci.com/gh/Hello-bar/hellobar_new)


## Installation

HelloBar runs on Ruby version 2.3.4, so it is recommended to install the exact same version locally.


### Back-end

If you are running Bundler 1.* it is required to configure https sources for the gems when bundling locally:

```
echo 'BUNDLE_GITHUB__HTTPS: "true"' >> ~/.bundle/config
```


Install all the gems:

`bundle install`


Setup the `secrets.yml` file:

`cp config/secrets.yml.example config/secrets.yml`

Setup your `database.yml` file:

`cp config/database.yml.example config/database.yml`
  
Setup your local database:

`rake db:setup`

You can run your application locally on `localhost:3000` or via
`local.hellobar.com` vhost as this domain has been setup to resolve to
`127.0.0.1`.

Credentials in config/secrets.yml.example are setup to handle both cases.

In case you want to run the app locally on a different domain/port you need to
visit https://console.developers.google.com/apis/credentials?project=hellobar-oauth
and add new Google OAuth credentials to be able to log in.


Here's the list of additional settings in `secrets.yml`, which might be needed to be set in your local development environment:
* `aws_access_key_id`
* `aws_secret_access_key`
* `deliver_emails`
* `geolocation_url`
* `host`
* `sendgrid_password`

If you want to use service providers integrations in the development environment,
you need to update `config/secrets.yml` with appropriate credentials, which can
be found at Confluence: https://crossover.atlassian.net/wiki/display/XOHB/Systems


### Front-end

Install `node.js`

You actually need to install `node@6` so if you have a later version of node, first run `brew install node@6` then `brew unlink node` then `brew link node@6`. Otherwise just run `brew install node`

Install `yarn`, and `ImageMagick`

```
brew install yarn
brew install imagemagick
```

Install `bower` and `ember-cli` globally:

```
yarn global add ember-cli
yarn global add bower
```

Install all dependencies:

```
cd editor/
yarn install
bower install
```

Then build the Ember application:

```
ember build --environment=production
```

The above command will build the js/css files for the Ember part of the application. It will store
them in the `editor/dist/assets` directory. This directory is then being included in the Rails
Assets Pipeline.

In development, it is recommended to use the `--watch` option, like this:

```
ember build --environment=production --watch
```

So that your Ember app is being recompiled on every changed.

(in OS X it also helps to install watchman in this case: `brew install watchman`).


### MS Windows

See [wiki](https://github.com/CrazyEggInc/hellobar_new/wiki/Windows-Environment-Setup)

### Ubuntu (Linux)

See [wiki](https://github.com/Hello-bar/hellobar_new/wiki/Application-Setup-on-Ubuntu-(Linux))



## Icons / Icon font

Compiling custom icons into a font file:
https://crossover.atlassian.net/wiki/display/XOHB/Compiling+custom+icons+into+font+file


## Testing generated site scripts

Just open `http://localhost:3000/test_site` to see the most recently updated `Site`.
(Note: this will show an error if you haven't created a `Site` instance yet)

You can specify `id` param for the exact site you want: `http://localhost:3000/test_sites/133`

If you are working on css/js of script you might want to fully regenerate script on every reload.
Use the `fresh` param then: `http://localhost:3000/test_site?fresh`



## Running specs

Currently we use Chrome --headless for all our feature

`brew install chromedriver`

### Rails specs

Integration tests run in the `spec/features` directory. They use the
`lib/site_generator.rb` to create an html file in the `public/integration` directory.
The filename is a random hex.

Capybara navigates to the public html file in order to test interactions.

To test the content of the iframe use `within_frame`.

To test adding or removing the iframe use
`page.driver.browser.frame_focus`.

Watch out for animations and other asynchronous or delayed interactions.
You may need to fiddle with the `Capybara.default_max_wait_time` in
`spec/spec_helper`.

Running Rails specs:

```
bundle exec rspec spec
```


### Rails specs "don'ts"

* don’t use `around`; use `before` and `after` instead
* don’t use `travel_to`, use `Timecop.travel` instead


## Development Workflow

https://crossover.atlassian.net/wiki/display/XOHB/Development+workflow



## Site script installation in development

We have Lambda function checking if the site script is installed. It sends a POST request to the Rails app
with appropriate value. Since there is no way to make AWS Lambda communicate with your locally installed
application, the only way to mark a script as installed is to update it from the console:

```ruby
Site.first.update_column :script_installed_at, Time.current
```


## Deployments

In order to do deployments, your public ssh key needs to be added to the appropriate server(s) first.
Then to do a production deploy from **master**:

```
cap production deploy
```

To do a staging deploy from a branch called `some-branch`:

```
cap staging deploy BRANCH=some-branch
```

To do an edge deploy:

```
cap edge deploy BRANCH=other-branch
```

### Using live version of hellobar modules from dev server
In order to use live version from hellobar_modules project do following:

- in `hellobar_modules` directory run the dev server, i.e. `npm run dev`
- add `local_modules_url: 'http://localhost:9090/modules.bundle.js'` into `config/secrets.yml` (see secrets.yml.example)  
- enjoy! :)

### Updating hellobar modules version

In order to deploy a new version of hellobar static script run following: 

```
rake modules:bump
```

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



## Live testing/QA info

Test site for both edge/staging: http://teampolymathic.github.io/hellobar_testing/


**Edge:**
http://edge.hellobar.com/
user: edge-test@polymathic.me
pword: password
site: teampolymathic.github.com

**Staging:**
http://staging.hellobar.com/
user: staging-test@polymathic.me
pword: password
site: teampolymathic.github.com

**Production:**
https://hellobar.com
user: prodtest@polymathic.me
pword: password
site: teampolymathic.github.com


## Generate Reports

### 1. Generate Application Security Vulnerabilities Report

From the terminal, go to your root of the app and run following command:

```
brakeman
```

## Running Hello Bar via Docker (Proceed into this section with caution. It's possibly a bit outdated...)

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

Once your `database.yml` and `secrets.yml` files are how you like them, run the following commands in a `Docker Quickstart Terminal`:

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

Note: if you want to set the RAILS_ENV, you can run the commands via bash using something like: `docker exec -it hellobarnew_web_1 /bin/bash -c "RAILS_ENV=test bundle exec rake db:setup"`

In the above example, `hellobarnew_web_1` is the name of the web container.

### 4. Accessing the dockerized Hello Bar in your browser

`docker-compose up` will automatically set up the app to listen on port 80. You can get the IP address of Docker's VM using `docker-machine ip` on the command line.

In order for the Google OAuth to work properly, you'll need to update your `/etc/hosts` file to map `local.hellobar.com` to your VM's IP address. For example, if your VM IP is `192.168.99.100`, you'll add the following line to `/etc/hosts`

```
192.168.99.100 local.hellobar.com
```

Navigating to [local.hellobar.com](http://local.hellobar.com) will then point to your local dockerized copy of Hello Bar


### 5. Enabling SSH within the container

If you need to use SSH from within the web container (e.g. deploying via capistrano), you can use the following commands to add your SSH keys and known hosts to the dockerized environment:

```bash
$ docker run --rm --volumes-from=hellobarnew_agent_1 -v ~/.ssh:/ssh -it whilp/ssh-agent:latest ssh-add /ssh/id_rsa
$ docker run --rm --volumes-from=hellobarnew_agent_1 -v ~/.ssh:/ssh -it whilp/ssh-agent:latest cp /ssh/known_hosts /root/.ssh/known_hosts
```

You'll want to substitute your private key name and agent container (the default is `hellobarnew_agent_1`)

## Local Configuration

For local settings of the application we have added `config/initializers/local.rb` to .gitignore.
You can for example configure mailcatcher instead of sending emails directly via SendGrid.
