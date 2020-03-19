<script type='text/coffeescript'>
import { onMount } from 'svelte'

import lzString from 'lz-string'

import renderTaskpaper from './cs/render-taskpaper.coffee'

# Never fulfilled; used as a placeholder.
EMPTY_PROMISE = new Promise () -> 'Empty Promise'

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

rendered = EMPTY_PROMISE

onMount () ->
    rendered = renderTaskpaper text

</script>

<template lang=pug>
    h1 View

    h2 name {name}
    h2 text
    +await('text then text')
        pre {text}
        +catch('error')
        p {error}
    +await('rendered')
        div Loading...
        +then('rendered')
            h2 rendered
            div {@html rendered.count}
            div.content {@html rendered.html}
        +catch('error')
            p {error}
</template>


<style global>
    .content {
        white-space: pre-wrap;
        display: inline-block;
        tab-size: 40px;
    }

    .content [data-type="project"] { font-weight: bold; }
    .content [data-type="note"] { font-style: italic; }
    .content span[tag] { color: #2aa198; font-weight: normal }

    .content [data-done] { text-decoration: line-through; }
    .content [is-context='true'] { opacity: 44%; }

    .content span[link] { position: relative;}

    .content ul,
    .content li,
    .content p {
        list-style-type: none;
        margin: .38em auto;
    }
</style>

