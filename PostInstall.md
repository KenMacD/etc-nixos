# Post Install Setup

## Firefox

### about:config

* browser.cache.disk.parent_directory "string" "/run/user/1000/firefox" (move to ramdisk)
* browser.sessionstore.interval 600000 (10m)
or maybe:
* browser.cache.disk.enable false

* toolkit.legacyUserProfileCustomizations.stylesheets true

### firefox profile: .mozilla/firefox/___/chrome/userChrome.css

```css
#TabsToolbar { visibility: collapse !important; }
#sidebar-box { min-width: 0px !important; }
```

### Font sizes, may want to use wdisplay scaling and/or for Firefox

* ui.textScaleFactor 120
* browser.tabs.inTitlebar = 0

### Allow adding search engines

* browser.urlbar.update2.engineAliasRefresh = true
* Add ghnix: <https://github.com/search?type=code&q=language%3ANix+%s>
