# Bulk import Series into Radarr for the lazy-man.

Similar to the bulk import movies UI script, this can be run in the browser to quickly add your existing TV series into Radarr, without having to manually click through each one and add.. (In my case, this is great if you've been previously using Sonarr, all your files are in order, and you're recovering from a server crash)

Run this script in your browser's developer tools (i.e. Chrome DevTools Console), then go grab a beer:

```javascript

function addSeries() {

    // First scroll to the bottom of the page so we've loaded all the data from the Sonarr api...
    // Then start clicking the 'add' button...

    var scrollBottom = setInterval(function(){
        // Scroll to bottom of page...
        window.scrollTo(0,document.body.scrollHeight);
    }, 10000);

    // Start processing/adding after 3 mins..
    setTimeout(prepareAddSeries, 5 * 60 * 1000)

    function prepareAddSeries() {
        clearInterval(scrollBottom);
        clickAddButtons();
    }

    function clickAddButtons() {
        var buttons = $("button.btn.btn-success.add.x-add").toArray();
        (function next() {
            $(buttons.shift()).click();
            if (buttons.length) {
                // Wait 5 seconds between adding series and clicking the next series...
                setTimeout(next, 5000);
            }
        })();
    }

}

addSeries();
```
