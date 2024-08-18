# Container setup for eTax.zug (Linux)

This is a `Containerfile` for [eTax.zug](https://www.zg.ch/behoerden/finanzdirektion/steuerverwaltung/eTax.zug).

If you have an existing directory from last year, you should rename it to avoid conflicts (i.e. `mv etax etax_2022`).
You will probably need to select `/home/taxpayer/etax_zug` as the installation directory.
Otherwise the entrypoint script might behave strange.
For now there is a symlink from the _current_ etax default directory to it but they could change it with the next release. Maybe we could establish a more robust logic here though.

Also you should save your tax data in `/home/taxpayer/Steuerfaelle`.
Otherwise the data won't be persisted after you threw the container away!

## Using the Containerfile

You can build the image by calling

```bash
$ docker build --build-arg HOST_GID=$(id -g) --build-arg HOST_UID=$(id -u) -t etax_zug -f Containerfile .
Sending build context to Docker daemon  93.18kB
…
Successfully tagged etax_zug:latest
```

You can also use [Podman](https://podman.io/) instead of Docker:
```bash
$ podman build --build-arg HOST_GID=$(id -g) --build-arg HOST_UID=$(id -u) -t etax_zug -f Containerfile .
```

After a successful build you should be able to run eTax Zug by calling

```bash
$ bash run.sh
No installation was found. Downloading https://etaxdownload.zg.ch/2042/eTaxZGnP2042_64bit.sh to eTaxInstaller.sh.
…
```

## Bugs

### Links

Because the image should be small and therefore doesn't contain a browser you can't click on links.
Right click + copy would be nice but it seems that the folks at [Information Factory AG](https://www.information-factory.com/) didn't implement this yet.

### Wayland

You need to run the container with `--env=DISPLAY` and `--env=QT_X11_NO_MITSHM=1` to make it work with Wayland.

```bash
$ xhost +SI:localuser:$(id -un)

$ podman run --rm -it --env=DISPLAY --env=QT_X11_NO_MITSHM=1 -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/taxpayer/etax_zug:/home/taxpayer/etax_zug etax_zug
```

## HiDPI-Displays

This is a Java application. Meaning it might not work well with all of your _native_ UI settings.
If you are using a display with high DPI and the fonts are very small, you might want to edit the file `etax/eTax.zug 2023 nP` after the first start.

### uiScale

Setting `uiScale` doesn't seem to work any more:

So for instance from

```bash
$INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java" "-splash:$app_home/.install4j/s_1wbh84j.png" …
```

to

```bash
$INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java" "-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel" "-Dsun.java2d.dpiaware=true" "-Dawt.useSystemAAFontSettings=on" "-Dsun.java2d.uiScale=2" "-splash:$app_home/.install4j/s_1wbh84j.png" …
```

### `-Dsun.java2d.ddscale`

This doesn't seem to work either

```bash
$INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java" "-Dsun.java2d.ddscale=true" "-splash:$app_home/.install4j/s_1wbh84j.png" …
```

### environment variable GDK_SCALE

This doesn't seem to work either

```bash
GDK_SCALE=2 $INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java" "-splash:$app_home/.install4j/s_1wbh84j.png" …
```
