# Hello Bar 3.0

Made with love.

## Environment Setup

### Mac OS

install dependancies (fontforge and ttfautohint support local compilation of font files)

`brew install fontforge ttfautohint eot-utils`

Bundle install all the gems

`bundle install`

Setup your database.yml file

`cp config/database.yml.example config/database.yml`

Setup the settings.yml file

`cp config/settings.yml.example config/settings.yml`

You'll need to manually add oauth related account keys to settings.yml to be able to run the site locally

Let rake setup and migrate all your databases

`rake db:setup`

### MS Windows

#### Prerequisites

Before launching project environment make sure you've installed the following:

- Ruby v2.1.8 \*
- Ruby on Rails v4.2 \*
- Ruby Bundler
- Ruby DevKit
- [MySQL v5.7.13](https://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-web-community-5.7.13.0.msi) \*
- [QT v4.8.6](https://download.qt.io/archive/qt/4.8/4.8.6/qt-opensource-windows-x86-mingw482-4.8.6-1.exe) \*

For the first 4 instances it's recommended to use [Rails Installer 3.1.1](https://s3.amazonaws.com/railsinstaller/Windows/railsinstaller-3.1.1.exe) 
which covers all the needed features and simplifies installation process.

When installing MySQL it's not necessary to setup wide range of SQL clients (MySQL for Excel, VisualStudio, Workbench, etc.)
You will be prompted to select which parts should be installed: choose "custom" option and select only 
`MySQL Server`, `Notifier`, maybe `ODBC Connector` and `Samples and Examples`. The other parts are left at your discretion.

\* *Listed versions are recommended but not necessary: their compatibility was checked empirically.*

#### Setting up gems

TODO: `brew install fontforge ttfautohint eot-utils` - find analogy for Windows

In the project root run

`bundle install`

##### Troubleshooting

> Most likely during the installation you'll see an error related to `capybara-webkit` gem. It's a known problem. 

In case of problems with Capybara you need to install `QT` library (see above) and bundle `capybara-webkit` manually from Git repository:

1. Add `C:/Qt/4.8.6/bin` (or your custom path to Qt 'bin' directory) 
to the `PATH` envrionment variable ([lern more](http://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/) 
on how to do it). *Note that having '4.8.6' version is crucial as it contains important fixes comparing to older versions. For using older 
versions see [instruction on google groups](https://groups.google.com/forum/#!topic/capybara-webkit/2tnnGLkrQkU). Newer versions were attempted
unsuccessfully*.
2. Clone the latest version of [Capybara-webkit](https://github.com/thoughtbot/capybara-webkit) from github somewhere to your drive.
3. Navigate to the cloned folder (e.g. `cd /c/capybara-webkit`) and run `bundle install`.
4. Navigate to Hellobar project root and run `gem install capybara-webkit`.

Now `capybara-webkit` should be installed successfully. Try running `bundle install` again to make sure 
all dependencies are installed without errors.

In case of any other trouble try [this](https://groups.google.com/forum/#!topic/capybara-webkit/2tnnGLkrQkU) verbose instruction.

#### Initializing database

After installing MySQL configure it with root user credentials.

Setup your `database.yml` file:

`cp config/database.yml.example config/database.yml`

Open it and add your MySQL root password to the `password:` field.

Setup `settings.yml` file:

`cp config/settings.yml.example config/settings.yml`

Try running `rake db:setup`.

##### Troubleshooting

###### TZInfo::DataSourceNotFound

> There might occur an error "TZInfo::DataSourceNotFound".

If it's the case, try installing that gem manually:

`gem install tzinfo-data`

If it doesn't help, read more on possible solutions [here](https://github.com/tzinfo/tzinfo/wiki/Resolving-TZInfo::DataSourceNotFound-Errors).

###### LoadError: bcrypt_ext

> There might occur an error related to `bcrypt` gem: *LoadError: cannot load such file -- bcrypt_ext*.

There are a few ways to fix bcrypt error (read more [here](https://github.com/codahale/bcrypt-ruby/issues/128)).

One of them (checked) is the following:

1. Try `gem uninstall bcrypt` and `gem uninstall bcrypt-ruby` and install them again with `--platform=ruby` option.
2. If doesn't help, open your Ruby gems directory, e.g. `C:\RailsInstaller\Ruby2.1.0\lib\ruby\gems\2.1.0\gems`.
3. Find all bcrypt-related gems (e.g. `bcrypt-3.1.11`, `bcrypt-3.1.7-x86-mingw32`, etc.).
4. One (or some) of them should contain file `lib/bcrypt_ext.so`. Copy this file and paste into `lib` library inside of other 
bcrypt-related gems where it is absent. *It's actually quite a dirty workaround, so if you come up with a better one, feel free to edit this doc.*

Try running `rake db:setup` again.

###### Older rake version

> You could also see an error stating that "You have already activated rake 10.1.0, but your Gemfile requires rake 10.3.2" or similar.

If that's the case just try running rake prefixed with 'bundle exec' as it's suggested in the stack trace, e.g:

`bundle exec rake db:setup`

#### Running local server

Run `rails server`. There could occur the same errors as described in "Initializing database" section above. Try fixing them same way, if you haven't.

When server is up and running, navigate to `localhost:3000` in your browser. Congratulations!

### Creating local account

To log in to locally deployed project you need to create a user in database.

Open rails console in your terminal using command:

`rails c`

Type the following command:

`User.create(email: 'test@mail.com', password: 'yourpass')`

If it fails saying that "hellobar_wordpress_development db is missing", try removing whole `wordpress_development` section 
in `database.yml` file and repeat the previous command. Then [log in to Hellobar](http://localhost:3000/users/sign_in)
using credentials you've set in the command.

### Front End

NOTE: install fontforge locally first with `brew install fontforge ttfautohint`
To add a new icon to the custom icon font file - add the icon svg file to app/assets/icons and run
`rake icon:compile`

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

To generate a site html file at an arbitrary location:

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

Capybara navigates to the public html file in order to test interactions.

To test the content of the iframe use `within_frame`.

To test adding or removing the iframe use
`page.driver.browser.frame_focus`.

Watch out for animations and other asynchronous or delayed interactions.
You may need to fiddle with the `Capybara.default_wait_time` in
`spec/spec_helper`.

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
