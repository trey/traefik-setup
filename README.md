# Set Up Traefik on DigitalOcean to Serve Multiple Docker-Powered Sites on a Single Droplet

I had this information living in a few different places, and I don’t want to mess around with forgetting something crucial when I’m trying to get something done.

The bulk of the information on Traefik is from this tutorial:

[How To Use Traefik as a Reverse Proxy for Docker Containers on Ubuntu 18.04 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-18-04)

---

## Table of Contents

1. [Initial Setup](#initial-setup)
    1. [Set Up a (Sub-)Domain to Use as a Traefik a Dashboard](#set-up-a-sub-domain-to-use-as-a-traefik-a-dashboard)
    1. [Create an Encrypted Password to Access Traefik’s Dashboard](#create-an-encrypted-password-to-access-trafiks-dashboard)
    1. [Set Up a Network in Docker and a File for Let’s Encrypt](#set-up-a-network-in-docker-and-a-file-for-let’s-encrypt)
    1. [Install and run Traefik](#install-and-run-traefik)
1. [Set up Supervisor to Restart Traefik as Needed](#set-up-supervisor-to-restart-traefik-as-needed)
1. [Set Up a New Site](#set-up-a-new-site)
    1. [Set Up a (Sub-)Domain for A New Site](#set-up-a-sub-domain-for-a-new-site)
    1. [Configure Docker to Play Nice with Traefik](#configure-docker-to-play-nice-with-traefik)
    1. [Set up Git to Be Able to Deploy Automatically](#set-up-git-to-be-able-to-deploy-automatically)
    1. [Start It Up](#start-it-up)
    1. [Set up Git to Deploy on Push](#set-up-git-to-deploy-on-push)
    1. [Set Up the New Site with Supervisor to Restart as Needed](#set-up-the-new-site-with-supervisor-to-restart-as-needed)

---

## File Index:

| File                                                        | Location on Server                                 |
| ----------------------------------------------------------- | -------------------------------------------------- |
| [`traefik.toml`](traefik/traefik.toml)                      | `~/traefik.toml`                                   |
| [`traefik.sh`](traefik/traefik.sh)                          | `/usr/local/bin/traefik.sh`                        |
| [`traefik.conf`](traefik/traefik.conf)                      | `/etc/supervisor/conf.d/traefik.conf`              |
| ---                                                         | ---                                                |
| [`example_site.sh`](example-site/example_site.sh)           | `/usr/local/bin/[example-site].sh`                 |
| [`example_site.conf`](example-site/example_site.conf)       | `/etc/supervisor/conf.d/[example-site].conf`       |
| [`post-receive-hook.sh`](example-site/post-receive-hook.sh) | `~/repos/[example-project].git/hooks/post-receive` |

---

_Unless otherwise noted, every command in these instructions should be run from the Droplet’s command line._

## Initial Setup

Start with a [Docker Droplet](https://marketplace.digitalocean.com/apps/docker) and have followed [these instructions](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04) including creating a non-root user account.

### Set Up a (Sub-)Domain to Use as a Traefik a Dashboard

Log into your domain registrar and set up an **A record** to point to the IP address of the Droplet.

### Create an Encrypted Password to Access Traefik’s Dashboard

Don’t skip this step. At first, I thought this was something you could just create in 1Password be done. However, you don’t use the password itself in the Traefik configuration file, you use the encrypted version of it. By all means, generate and store the actual password in 1Password, but you need this utility to generate the encrypted version of that password.

```shell
sudo apt-get install apache2-utils
```

Then go ahead and create your password in 1Password and use it here:

```
htpasswd -nb admin your_secret_password
```

You should see some output that looks like this. Copy what comes after `admin:`

```
admin:your_encrypted_password
```

Copy [`traefik.toml`](traefik/traefik.toml) to your user folder on DigitalOcean and replace `your_encrypted_password` with your actual encrypted password.

### Set Up a Network in Docker and a File for Let’s Encrypt

Create a shared network for all the Docker-powered sites to use:

```
docker network create web
```

Create the file that will hold all our Let’s Encrypt info:

```
touch acme.json
chmod 600 acme.json
```

### Install and run Traefik

```shell
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD/traefik.toml:/traefik.toml \
  -v $PWD/traefik_dynamic.toml:/traefik_dynamic.toml \
  -v $PWD/acme.json:/acme.json \
  -p 80:80 \
  -p 443:443 \
  --network web \
  --name traefik \
  traefik:v2.4.7
```

Because we’re going to set up Supervisor, you probably won’t have to do this, but to start it back up manually:

```shell
docker start traefik
```

Now you should be able to go to your Traefik dashboard’s domain and log in with the username of `admin` and the password you created earlier.

---

## Set up Supervisor to Restart Traefik as Needed

This makes sure if the server restarts or the Traefik app stops running for some reason, it'll be restarted automatically.

1. [Set up Supervisor:](https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps)

```shell
sudo apt-get install supervisor
sudo service supervisor restart
```

2. Copy [`traefik.conf`](traefik/traefik.conf) to `/etc/supervisor/conf.d/traefik.conf`.
3. Copy [`traefik.sh`](traefik/traefik.sh) to `/usr/local/bin/traefik.sh`
4. Tell Supervisor to look for the new changes and load them.

```shell
# Look for changes.
sudo supervisorctl reread

# Run the changes.
sudo supervisorctl update
```

Pro tip: you can check on running items in Supervisor:

```shell
sudo supervisorctl

supervisor> status
supervisor> stop [program_name]
supervisor> restart [program_name]
supervisor> quit
```

---

## Set Up a New Site

Note: sites/apps live in `~/apps` and their corresponding repos live in `~/repos`.

### Set Up a (Sub-)Domain for A New Site

Log into your domain registrar and set up an **A record** to point to the IP address of the Droplet.

### Configure Docker to Play Nice with Traefik

Review the example [`docker-compose.yml`](example-site/docker-compose.yml).

Note that every new site will need a unique `traefik.port`.

- [ ] Flesh this section out. Port stuff feels just a _little_ too magical.

### Set up Git to Be Able to Deploy Automatically

1. Set up folders and a new, empty git repository.

```shell
mkdir ~/apps/[new-project]
mkdir ~/repos/[new-project].git
cd !$
git init --bare --initial-branch=main
```

(Obviously, only set the initial branch to `main` if that’s how your repo is set up.)

2. On your Mac, connect the local repo to the one on DigitalOcean.

```shell
git remote add digitalocean ssh://trey@[IP address]/home/trey/repos/[new-project].git
```

3. Set up a post-receive hook. Create [a barebones file](example-site/post-receive-hook-first.sh) in the `~/repos/[new-project]/hooks/` folder called `post-receive` This version of the file is just to get things in place and try them out. [We’ll update it shortly.](#set-up-git-to-deploy-on-push)
4. Make the file executable with  `chmod +x post-receive`.
5. Run `git push digitalocean main` (or whatever branch you want) to get the code onto the server.

### Start It Up

```
cd ~/apps/[new-project]

docker-compose up -d --build
```

The site should work now. 🎉 If not, once you figure out what else needs to happen, we’ll configure it to happen automatically the next time you do a `git push`.

### Set up Git to Deploy on Push

Now that you know that the site runs and have figured out any peculiarities with it, you can take that knowledge and make it happen whenever you do a `git push`.

Update the post-receive hook for your repository with the stuff in [this updated example](example-site/post-receive-hook.sh) as well as anything else you’ve learned. Then put this file in your `scripts/` folder for safe keeping.

Now when you `git push digitalocean`, all the things needed to update and restart your app will happen automatically.

### Set Up the New Site with Supervisor to Restart as Needed

To make sure the app comes back to life in the event it stops running or the server reboots, set it up with Supervisor.

1. Copy [`example_site.conf`](example-site/example_site.conf) to your `scripts/` folder and rename it.
2. Copy [`example_site.sh`](example-site/example_site.sh) to your `scripts/` folder and rename it.
3. Copy the files to where they need to live on the server.

```shell
sudo cp [your .conf file] /etc/supervisor/conf.d/
sudo cp [your .sh file] /usr/local/bin/
sudo chmod +x /usr/local/bin/[your .sh file]
```

4. Tell Supervisor to look for the new changes and load them.

```shell
# Look for changes.
sudo supervisorctl reread

# Run the changes.
sudo supervisorctl update
```

[See also.](#set-up-supervisor-to-restart-traefik-as-needed)
