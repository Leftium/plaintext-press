<script type='text/coffeescript'>
import lzString from 'lz-string'

parseLocator = (locatorString) ->
    full = data = locatorString
    type = 'urlencoded'
    if locatorString? and matches = locatorString.match /([^:]*):([\s\S]*)/
        [full, type, data] = matches

    return { full, type, data }

fetchText = (url) ->
    if not url then throw 'Error: Either url or text parameter required.'

    url = url.replace /www.dropbox.com/, 'dl.dropboxusercontent.com'
    res = await fetch url

    if res.status is 200
        return res.text()
    else
        throw "#{res.status}: Error loading #{url}"

fetchLocator = (locator) ->
    name = text = ''
    if not locator? then return { name, text }

    try
        switch locator.type
            when 'local'
                # Todo
                text = 'TODO: Type local: not implemented, yet!'
            when 'lzstring'
                # Type lzstring should always have a filename
                # separatd by a '/'.
                data = lzString.decompressFromEncodedURIComponent locator.data
                if matches = data.match ///([^/]*)/([\s\S]*)///
                    [_, name, text] = matches
                else
                    text = data
            when 'urlencoded'
                # Type urlencoded locators nave no name; only text
                # Use type lzstring to attach a name
                text = locator.data.replace /\+/g, '%20'
                text = decodeURIComponent text
            else
                # Handle types http, https, ftp, etc...
                name = locator.data.split('/').pop()
                text = fetchText locator.full

    return { name, text }




locator = parseLocator location.pathname[1..].replace(/\/+$/, '')
{name, text} = fetchLocator locator
console.log locator
</script>

<template lang=pug>
    h1 View

    h2 name {name}
    h2 text
    +await('text then text')
        p {text}
        +catch('error')
            p {error}
</template>

<style>

</style>
