# Set Up Traefik on DigitalOcean to Serve Multiple Docker-Powered Sites on a Single Droplet

I had this information living in a few different places, and I don’t want to mess around with forgetting something crucial when I’m trying to get something done.

The bulk of the information on Traefik is from this tutorial:

[How To Use Traefik as a Reverse Proxy for Docker Containers on Ubuntu 18.04 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-18-04)

---

## File Index:

| File                                                        | Location on Server                               |
| ----------------------------------------------------------- | ------------------------------------------------ |
| [`traefik.toml`](traefik/traefik.toml)                      | `~/traefik.toml`                                 |
| [`traefik.sh`](traefik/traefik.sh)                          | `/usr/local/bin/traefik.sh`                      |
| [`traefik.conf`](traefik/traefik.conf)                      | `/etc/supervisor/conf.d/traefik.conf`            |
| ---                                                         | ---                                              |
| [`example_site.sh`](example-site/example_site.sh)           | `/usr/local/bin/example-site.sh`                 |
| [`example_site.conf`](example-site/example_site.conf)       | `/etc/supervisor/conf.d/example-site.conf`       |
| [`post-receive-hook.sh`](example-site/post-receive-hook.sh) | `~/repos/example-project.git/hooks/post-receive` |

---

_Unless otherwise noted, every command in these instructions should be run from the Droplet’s command line._

## Initial setup

Start with a [Docker Droplet](https://marketplace.digitalocean.com/apps/docker) and have followed [these instructions](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04) including creating a non-root user account.

### Set Up a (Sub-)Domain to Use as a Traefik a Dashboard

Log into your domain registrar and set up an **A record** to point to the IP address of the Droplet.

### Create an Encrypted Password to Access Trafik’s Dashboard

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

### Get Things Ready for Traefik

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
  -v $PWD/acme.json:/acme.json \
  -p 80:80 \
  -p 443:443 \
  -l traefik.frontend.rule=Host:proxy.treylabs.com \
  -l traefik.port=8080 \
  --network web \
  --name traefik \
  traefik:1.7.2-alpine
```

_I wish I knew why we can only use version 1.7.2. I tried using the latest at some point with no luck. This stuff feels enough like it’s held together with baling wire that I didn’t feel like pressing it. Maybe one day._

Because we’re going to set up Supervisor, you probably won’t have to do this, but to start it back up manually:

```shell
docker start traefik
```

Now you should be able to go to your Traefik dashboard’s domain and log in with the username of `admin` and the password you created earlier.

---

## Set up Supervisor to Restart Traefik as Needed

- [Set up Supervisor.](https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps)
- …

---

## Set Up a New Site

- …
<!-- TODO
- Add all the stuff from Bear "Set up a new Docker/Traefik site"
- ~/apps
- ~/repos
 -->

### Automatic Deployments with Git

Set up a new, empty git repository.

```
mkdir ~/repos/[new-project].git
cd !$
git init --bare --initial-branch=main
```

Set up a post-receive hook for it. Create [a file](example-site/post-receive-hook.sh) in the `hooks/` folder called `post-receive` (also put this file in your `scripts/` folder for safe keeping).

Then make the file executable with  `chmod +x post-receive`.

On your Mac, connect the local repo to the one on DigitalOcean.

```
git remote add digitalocean ssh://trey@[IP address]/home/trey/repos/[new-project].git
```

### Set Up the New Site with Supervisor to Restart as Needed

1. Add example-site files where they need to go.
2. Run these commands to make the changes take effect:

```shell
# Look for changes.
supervisorctl reread

# Run the changes.
supervisorctl update
```

You can check on running items:

```shell
sudo supervisorctl

supervisor> status
supervisor> stop [program_name]
supervisor> restart [program_name]
```
