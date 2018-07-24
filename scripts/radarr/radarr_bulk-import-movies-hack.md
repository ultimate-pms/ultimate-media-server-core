# Bulk import movies into Radarr for the lazy-man.

I wrote this quickly in response to issue: [Radarr/#2273](https://github.com/Radarr/Radarr/issues/2273)

If you're like me and trying to import thousands of pre-downloaded movies (around 4,000+ movies) into Radarr, you're not going to want to click through the web-ui manually and add them all...

Here's a quick javascript hack you can run in your browser's developer tools (i.e. Chrome DevTools Console), then go grab a beer:

**NB ONLY TESTED ON:** *Radarr Ver. 0.2.0.1120*

```javascript

function addMovies() {
    var rowCount = $('#x-movies-bulk >table >tbody >tr').length;
    if(rowCount => 10) {
        $('#x-movies-bulk > table > thead > tr > th.select-all-header-cell.renderable > input[type="checkbox"]').trigger('click');
        $('#x-toolbar > div > div.page-toolbar.pull-left.pull-none-xs.x-toolbar-left > div > div > div').trigger('click');

        setTimeout(function(){
            // Go to the next page...
            $('#x-movies-bulk-pager > div > ul > li:nth-child(4) > i').trigger('click');   
        }, 1000 * 15); 

    }
}

addMovies();
setInterval(addMovies, 1000 * 30)
```

> Be sure to leave the default "list size" to 15 (the smallest) -- The script will just select all the select boxes, click add selected, wait a few moments, and repeat until you're done...

-----------------------------------------------------------------------

Screenshot:

![Alt text](../screenshots/radarr_bulk-import-movies-hack.gif?raw=true)
