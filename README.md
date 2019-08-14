# Docker container for eTax.zug (Linux)

You will probably need to select `/home/taxpayer/etax_zug` as the installation directory.
Otherwise the entrypoint script might behave strange.
For now there is a symlink from the _current_ etax default directory to it but they could change it with the next release. Maybe we could establish a more robust logic here though.

Also you should save your tax data in `/home/taxpayer/Steuerfaelle`.
Otherwise the data won't be persisted after you threw the container away!

You should be able to run the eTax Zug by calling

```bash
bash run.sh
```

## Bugs

### Links

Because the image should be small and therefore doesn't contain a browser you can't click on links.
Right click + copy would be nice but it seems that the folks at ifactory didn't implement this.

## HiDPI-Displays

This is a Java application. Meaning it might not work well with all of your _native_ UI settings.
If you are using a display with high DPI and the fonts are very small, you might want to edit the file `etax/eTax.zug 2018 nP` after the first start.

Usually it should be enough to set `uiScale`.

So from

```bash
$INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java" "-splash:$app_home/.install4j/s_1wbh84j.png" …
```

to

```bash
$INSTALL4J_JAVA_PREFIX exec "$app_java_home/bin/java" "-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel" "-Dsun.java2d.dpiaware=true" "-Dawt.useSystemAAFontSettings=on" "-Dsun.java2d.uiScale=2" "-splash:$app_home/.install4j/s_1wbh84j.png" …
```
