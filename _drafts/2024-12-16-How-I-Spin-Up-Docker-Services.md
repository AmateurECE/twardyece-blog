The zwave-js documentation lists this command for running the application under
Docker:

```
docker run --rm -it -p 8091:8091 -p 3000:3000 --device=/dev/serial/by-id/ \ 
  insert_stick_reference_here:/dev/zwave -v $(pwd)/store:/usr/src/app/store \ 
  zwavejs/zwave-js-ui:latest
```

In my system, however, I keep volumes as subvolumes on a btrfs partition, and
use the `local` storage driver to allow containers to access them. I love this,
because it means I have one physical partition that I need to back up, and
that's where all of my non-version-controlled data needs to live. I'll set that
up for this service now.

```
# mount /dev/sde4 /mnt/Mount/
# btrfs subvolume create /mnt/Mount/@zwave_store
Create subvolume './@zwave_store'
# umount /mnt/Mount 
# podman volume create -o type=btrfs -o o=subvol=@zwave_store -o device=/dev/sde4 zwave_store
zwave_store
```

I know that `/dev` paths are not stable, so when I actually create a Quadlet
volume unit for this, I'll replace `/dev/sde4` with a disk ID under
`/dev/disk/by-uuid/`. This is only supposed to be a prototype for the current
boot, so I think I'm alright.

I could have also used a local directory for persisting the configuration, and
then later created the subvolume and `rsync`-ed the data over. I am pretty sure
that I'm going to need this service, though, so why make more work for myself?

Next is to run the container.

```
# podman run --rm -it -p 8091:8091 --network=public-services \
  --device=/dev/ttyUSB0:/dev/zwave -v zwave_store:/usr/src/app/store \
  docker.io/zwavejs/zwave-js-ui:latest
```

This particular application exposes a web server on port 8091. This setup is
convenient, because I can access that port from my local network and I don't
have to mess with my Nginx settings. When I'm ready to package and deploy the
service, I won't publish this port. If I choose to allow external access, I'll
create an Nginx configuration file for it.

For this particular application, though, I don't expect to want external access
to the web interface, at least in the near term. I only want Home Assistant to
access the application's web socket interface. Adding it to the same network as
I've done above is sufficient.

I loaded the web interface and set up my Z-Wave controller and the smart
switch. It wasn't as easy as I was hoping, but it was far easier than setting
up my smart bulb with a LocalTuya integration. I think I'll be seeking more
Z-Wave devices in the future.

I need to point Home Assistant to this service, which means we should probably
create a stable name for it. I usually name my services following the pattern
`(public|private)_<service_name>`. If the service is accessible from outside
the machine, it's `public`. Otherwise, it's private. I think I'd consider this
service to be private, so I shut the container down and add `--name
private_zwavejs` to the command above. Additionally, I change the `-it` to be
`-d` so that I can let the service run while I package it.
