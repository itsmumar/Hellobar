# Hello Bar 3.0

Made with love.

[![CircleCI](https://circleci.com/gh/Hello-bar/hellobar_new.svg?style=svg&circle-token=a40215cbc1e8ef0718fced860063731f53206e73)](https://circleci.com/gh/Hello-bar/hellobar_new)


## Installation

HelloBar runs on Ruby version 2.1.9, so it is recommended to install the exact same version locally.


### Back-end

Install all the gems:

`bundle install`


Setup your database.yml file

`cp config/database.yml.example config/database.yml`


Setup the settings.yml file

`cp config/settings.yml.example config/settings.yml`


You'll need to manually add oauth related account keys to settings.yml to be able to run the site locally

Let rake setup and migrate all your databases

`rake db:setup`


It is advised to run the application locally using the `local.hellobar.com` domain with an additional entry in `/etc/hosts`,
so that it resolves into `127.0.0.1`.

You need to visit https://console.developers.google.com/apis/credentials?project=hellobar-oauth
and setup or use existing Google OAuth credentials to be able to log in.

You need to add `google_auth_id` and `google_auth_secret` into `config/settings.yml`.


### Front-end

Install `node.js` together with `npm`:

```
brew install node
```

Install `bower` and `ember-cli` globally:

```
npm install -g ember-cli
npm install -g bower
```

Install all dependencies:

```
cd editor/
npm install
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



## Icons

Install all dependencies to support local font compilation:

`brew install fontforge ttfautohint eot-utils`

To add a new icon to the custom icon font file add the SVG file to `app/assets/icons` and run:

```
rake icons:compile
```


## Running specs

To run specs locally you need to have QT version 5.5+ installed locally. Installation instructions can be found here:

https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit


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


## Javascript specs

Teaspoon runs the `*_spec.js` files in `spec/javascripts/`.

The results of that suite can be seen at http://localhost:3000/teaspoon where you can also run individual js spec files.

To run the whole suite of Javascript specs execute:

```
rake teaspoon
```


Tests are divided into two groups:

* `generator` (tests `hellobar.base.js` and some other files)
* `project` (tests `assets/javascripts/` files).

To get the coverage of Generator:

```
teaspoon --suite=generator --coverage=generator
```

Coverage of Project:

```
teaspoon --suite=project --coverage=project
```



## Workflow

To add a new feature, make a branch off of **master**. Your branch name should start
with the JIRA issue number, like this:

```
git checkout -b XOHB-1083-switch-to-https-ruby-gem-sources
```


Next open a new pull request at GitHub with your changes. Be sure to include a link
to the JIRA card in the description and place the JIRA card number as a prefix in
your pull request name, like this: `[XOHB-1083] Switch to https Ruby gem sources`.



## Deployments

To do a production deploy from **master**:

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
`http://localhost:4567`

By default this will use the last site created to generate the js.

You can explicitly pass a site id as well:

```
rake test_site:generate[2]
```


#### Options

To generate a site html file at an arbitrary location:

```
rake test_site:file[2, '/Users/hb/index.html']
```

The above method is used by the capybara integration tests.

All of these rake tasks use the `lib/site_generator.rb` class as well as
an `HbTestSite` class defined within the rake task itself.


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
