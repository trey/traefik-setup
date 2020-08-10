# Set Up Traefik on DigitalOcean to Serve Multiple Docker-Powered Sites on a Single Droplet

I had this information living in a few different places, and I don’t want to mess around with forgetting something crucial when I’m trying to get something done.

The bulk of the information on Traefik is from this tutorial:

[How To Use Traefik as a Reverse Proxy for Docker Containers on Ubuntu 18.04 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-18-04)

---

_Every command in these instructions should be run from the Droplet’s command line._

## Initial setup

### Set Up a (Sub-)Domain to Use as a Traefik a Dashboard

Log into your domain registrar and set up an A record to point to the IP address of the Droplet.

### Create an Encrypted Password to Access Trafik’s Dashboard

Don’t skip this step. At first, I didn’t understand that this is not something you could just create in 1Password and ignore this part. You don’t use the password itself in the configuration file, you use the encrypted version of it. By all means, generate and store the actual password in 1Password, but you need this utility to generate the encrypted version of that password.

```shell
sudo apt-get install apache2-utils
```

Then go ahead and create your password in 1Password and use it here:

```
htpasswd -nb admin your_secret_password
```

Copy the entire output which should look like:

```
admin:your_encrypted_password
```

Copy the included `traefik.toml` file to your user folder on DigitalOcean and replace `your_encrypted_password` with your actual encrypted password.

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

You probably won’t have to do this, but to start it back up manually:

```shell
docker start traefik
```

Now you should be able to go to your Traefik dashboards domain and log in with the username of `admin` and the password you created earlier.

---

## Set up Supervisor to Restart Traefik as Needed

…

---

## Set Up a New Site

- [ ] Add all the stuff from Bear "Set up a new Docker/Traefik site"

### Automatic Deployments with Git
