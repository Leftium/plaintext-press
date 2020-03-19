<script type='text/coffeescript'>
import { onMount } from 'svelte'

import lzString from 'lz-string'

import renderTaskpaper from './cs/render-taskpaper.coffee'
import neatLinkify from './cs/neat-linkify.coffee'

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


renderTaskpaperResultsOrAll = (text, query, showParents) ->
    query = query or '*'
    { html, count } = await renderTaskpaper text, query, showParents

    # If no results default to showing all results as context.
    if not html
        { html } = await renderTaskpaper text, '*', showParents, true
        count = 'No results'

    return { html, count }



tpQuery = ''
showParents = false

locator = parseLocator location.pathname[1..].replace(/\/+$/, '')
{name, text} = fetchLocator locator


switch locator.type
    when 'lzstring', 'urlencoded'
        source = 'embedded in URL'
        if name then source = "#{name} (#{source})"
    when 'local'
        source = "#{name} (local browser)"
    else
        source = neatLinkify locator.full


rendered = EMPTY_PROMISE

onMount () ->
    rendered = renderTaskpaperResultsOrAll text


`$: rendered = renderTaskpaperResultsOrAll(text, tpQuery, showParents)`

</script>

<template lang=pug>
    header
        h2 Source: {@html source}
        div.controls
            span.taskpaper-query.inner-addon.left-addon
                i.fas.fa-search
                input(placeholder='TaskPaper Query' 'bind:value={tpQuery}' autofocus)
            span: label
                input('type=checkbox' 'bind:checked={showParents}')
                span Show Parents

            +await('rendered then rendered')
                span {@html rendered.count}
    main
        +await('rendered')
            div Loading...
            +then('rendered')
                div.content {@html rendered.html}
            +catch('error')
                p {error}
</template>


<style global>
    header {
        padding: 8px;
        border-bottom: 1px solid #586e75;
        background-color: #eee8d5;
        color: #657b83;
    }
    main {
        padding: 8px;
        background-color: #fdf6e3;
        color: #657b83;
    }
    .controls > span {
        margin: 0 4px;
        font-size: 14px;
    }

    .controls > span:last-child {
        margin-left: 40px;
        color: #93a1a1;
    }

    .taskpaper-query input:focus {
        outline: none;
    }

    .taskpaper-query {
        display: inline-block;
    }

    .taskpaper-query input {
        padding: 2px 2px;
        font-size: 14px;
        border-radius: 15px;
    }

    .inner-addon {
        position: relative;
    }

    /* style icon */
    .inner-addon .fas {
        position: absolute;
        padding: 7px;
        pointer-events: none;
        color: #ccc;
    }

    /* align icon */
    .left-addon .fas  { left:  2px; }
    .right-addon .fas { right: 0px; }

    /* add padding  */
    .left-addon input  { padding-left:  30px; }
    .right-addon input { padding-right: 30px; }

    label {
        display: initial;
    }

    input[type=checkbox] {
        margin: 3px 3px 3px 4px;
    }

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

