# Dockerized nfs

# Second Try

Get NFS working and NFS volumes working so slurm nodes could use them.

```
modprobe nfs
modprobe nfsd
docker-compose up
```


# First Try

I wanted to integrate this into the docker-compose.yml for the whole slurm cluster. 

This didn't work, really.   I couldn't get it work "out of the box".  This could be an alternate way to set up NFS, but it doesn't seem much easier than just using the host machine as the server...

## Create Real Volumne

```
docker volume create users_home
```

## Start nfs

```
docker run -it --hostname nfs-server --name nfs-server -e NFS_EXPORT_0='/users_home                  *(rw,no_subtree_check)' --privileged --expose 2049 --expose 111 --expose 32765 --expose 32767 --volume users_home:/users_home  erichough/nfs-server
```

This gives you a dockerize nfs serving the `users_home` volume.

## Create NSF Volume


```
docker volume create --opt addr=172.17.0.2,nolock,soft,rw users_home_nfs --opt device=:/users_home  --opt type=nfs --driver local 
```

This is a volume spec that will connect via NSF. 


## Start client that uses the nfs volume

You have to manually figure out the IP address, I couldn't get the name to resolve.

If you are cfiddle-dev container, you also need to do 
```
docker network connect bridge cfiddle-dev
```
Because cfiddle-dev is on a private network.

Then you can start the client:

```
docker run -it --volume users_home_nfs:/tmp --hostname nfs-c1 --name nfs-c1  nfs-tester  bash
```

and the volume will appear under tmp.

## WHat didn't work

I couldn't get the docker compose file to work right.  There seems to be some dependence on when the `nfs-server` is resolved when trying to connect the client.  I couldn't get it to work.


