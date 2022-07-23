# Simple Multi-User Jupyterlab using Docker and Tailscale

## Motivation

A few years ago, I set up and managed a Jupyter Hub for my Data Science team. It took a few iterations
to smooth out the sharp edges and make everything work just the way we wanted, but on a scale of one
to ten, the difficulties of set up and maintenance were a three at most.
Recently, I wanted to create a similar set up for a few members of my
family and some co-workers using a bare metal server I owned. I thought surely in the intervening years things had progressed to a stage
where a turn key deployment of Jupyter Hub was available.

## Existing Solutions

I found a couple of options. The first was [The Littlest Jupyter Hub](tljh.jupyter.org). The docs for Jupyter Hub
suggested TLJH was a perfect fit, and deployment would be a breeze. My requirements were mostly standard,
with a few exceptions. One, the whole deployment needed to be containerized, and two it needed to be
easy to customize the user's Jupyter environment. These customizations turned out to be too much for me and TLJH. After
many attempts and deep dive debugging sessions I abandoned TLJH as unworkable.

The Jupyter Hub docs also suggest a kubernetes based deployment, [Zero to Jupyter Hub](zero-to-jupyterhub.readthedocs.io). I have wanted to
dip my toe into the fashionable kubernetes waters and here was an opportunity. I recognized my lack of
familiarity with kubernetes so initially I dispensed with any non-standard customizations just to see
what the process of deployment was like. I immediately hit obstacles. Although the documentation is
written flawlessly, and presented in a style that manages to be both terse and informative, in the end
the results simply did not work. It probably could have worked with time and effort on my part, but my
goal to become familiar with kubernetes was a secondary goal of the project not the primary goal. So,
alas, I abandoned Zero to Jupyter Hub.

As a last ditch effort to stand up a personal Jupyter Hub, I decided to build upon a reference deployment
[given here](https://github.com/jupyterhub/jupyterhub-deploy-docker). The author is a significant contributor to the Jupyter Hub project surely his reference
implementation would work. Reading the code I could see where my customizations could be easily
added. I am sure it would have been easy to customize if it actually worked. Much to my
surprise and disappointment the reference deployment was not functional, not in the least.

If the above sounds bitter and angry, it is only because the experience left me bitter and angry. I had wasted a dozen or more hours over the course of several Saturday morning's, life's most valuable hours, for nothing.

## Solution

I ran my personal Jupyter Lab using Docker and that involved almost no effort. In fact, I ran several personal Jupyter Lab's for myself: one for work, one that could access a high-end GPU, another that was used for video editing. If only I could deliver the ease of running Jupyter Lab without the pain of Jupyter Hub to my family and colleagues.

This repo does just that. The `docker-compose.yml` file has service for each user. Each user is assigned their own port exposed on the host machine. Each user has their own personal volume which is mounted into
their home directory. There is also a shared volume which can be used to
easily share files among users. The initial setup of the compose is repetitive but simple, and incrementally adding or removing users is easy. Each user service described in `docker-compose.yml` has the same structure:

```
  jupyterlab_alice:
    build:
      context: jupyterlab
      args: *common-vars
    image: jupyterlab_img
    ports:
      - 18010:8888
    volumes:
      - jupyterlab_volume_alice:/home/user
      - jupyterlab_volume_shared:/home/user/shared
```

The name of the service is just the user's name appended to "jupyterlab", any name here will do as long as it is unique per user and a valid compose service name. Prefixing with "jupyterlab" allows these containers to standout and group together among the myriad other containers this server runs. The user service container builds from the Dockerfile in the jupyterlab folder. All user containers use the same image. Customizing any one user or group of users would be simple, just change their build context and image. The exposed port must be unique to each user, and it maps to 8888 in the container, the default jupyterlab port. Finally, a volume is allocated to each user and mapped to their home directory in the container and a shared volume is allocated to all users which is mapped to the `shared` directory under their home directory. The username is `user` for all users inside the container. This is a feature not a limitation. It makes it convenient for users to share notebooks that reference paths.

The `docker-compose.yml` file also specifies the initial password hash, as well as a token ([see how to create a hash here](https://jupyter-notebook.readthedocs.io/en/stable/public_server.html#preparing-a-hashed-password)). The password or the token can be used for access, and each user can change their password when they login. This may seem like lax security for a system that allows generous access to the server resources. It is, because we are not relying on jupyterlab for security, more on that later.

The jupyterlab image is built from the Dockerfile in the jupyterlab directory. It installs the usual suspects of the python data science stack. In addition, it installs a kernel for typescript, [tslab](https://github.com/yunabe/tslab). If you haven't tried typescript for data science, you're missing out. The Dockerfile also creates the `user` user and grants them sudo access. This allows individual lab users to install whatever they choose inside their personal container. The entrypoint for the container is the shell script `entrypoint.sh`. A default `jupyter_notebook_config.py` is also provided and copied to the appropriate place inside the container.

The lab can be build and started by running:

```
docker-compose build
docker-compose up
```

from the top level directory.

## Tailscale

It's all well and good to have multiple user jupyterlabs running on a server, but the users need access to them. As configured, a user just needs access to a single port on the server. One could provide that access using `ssh` and probably could secure it with some complex port forwarding gymnastics. However, with [Tailscale](tailscale.com), it is a simple matter to grant users secure access to a single port on a server.

In order to do so, install tailscale on the Jupyter Lab server (in fact, you might want to install tailscale on all your devices to gain access to them wherever you roam). Use the [sharing feature](https://tailscale.com/kb/1084/sharing/) to create a link for each Jupyter Lab user. This link will add the server to the user's tailscale network allowing them to access it as if it were on their local network.

You probably want to restrict the Jupyter Lab users to the single port they were given in the `docker-compose.yml` file. This can be done using Tailscale ACLs. Something like:

```
{
	"acls": [
		{
            "action": "accept",
            "src": ["alice@gmail.com"],
            "dst": ["*:18010"]
        },
		{
            "action": "accept",
            "src": ["bob@gmail.com"],
            "dst": ["*:18020"]
        },
```

as noted in the Tailscale docs, this access is scoped by the invite, so only the single port on the invited server is accessible.

Tailscale has restrictions on the number and role of users coming from specific domains. It is best to use generic domain emails (eg `gmail.com`) if you want to stay within the free tier of Tailscale.

## Connecting

With all of this in place, a user can access their Jupyter Lab from anywhere, via the Tailscale ip. For example, say that Alice sees the tailscale ip of the server as 100.91.200.44. Then she can point her browser at:

```
http://100.91.200.44:18010
```

and enjoy secure access to her own personal Jupyter Lab.

If this saves one person one Satyrday morning hour, it will have been worthwhile.
