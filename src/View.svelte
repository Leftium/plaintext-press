<script type='text/coffeescript'>
import { onMount } from 'svelte'

import lzString from 'lz-string'

import ClipboardInput from './components/ClipboardInput.svelte'
import ClipboardLink  from './components/ClipboardLink.svelte'

import renderTaskpaper from './cs/render-taskpaper.coffee'
import neatLinkify from './cs/neat-linkify.coffee'

# Never fulfilled; used as a placeholder.

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


renderTaskpaperResultsOrAll = (text, query, selectedTags, showParents) ->
    query = query or '*'
    { html, count, rest... } = await renderTaskpaper text, query, selectedTags, showParents

    # If no results default to showing all results as context.
    if not html
        { html } = await renderTaskpaper text, '*', [], showParents, true
        count = 'No results'

    return { html, count, rest... }

render = (text, query, selectedTags, showParents) ->
    {html, rest...} = await renderTaskpaperResultsOrAll(text, query, selectedTags, showParents)

    if html
        tmpDiv = document.createElement 'div'
        tmpDiv.innerHTML = html

        listItems = tmpDiv.querySelectorAll 'li'

        for listItem in listItems
            if matches = listItem.innerText.match /(^|\s)#([^#\s]*)/i
                listItem.id = matches[2].toLowerCase()

        html = tmpDiv.innerHTML

    return {html, rest...}


jumpToHash = () ->
    if target = document.querySelector(location.hash)
        y = target.offsetTop - 44

        window.scrollTo options =
            behavior: 'smooth'
            top: y


onHashChange = (e) ->
    jumpToHash()

onClick = (e) ->
    if document.selection # IE
        range = document.body.createTextRange()
        range.moveToElementText(main)
        range.select()
    else if window.getSelection
        range = document.createRange()
        range.selectNode(main)
        window.getSelection().removeAllRanges()
        window.getSelection().addRange(range)

    document.execCommand('copy')

onToggle = (e) ->
    if e.target.open
        descriptionInput.select()
    else
        queryInput.select()



url = new URL location

open = url.searchParams.get('advanced') is '1'
tpQuery = url.searchParams.get('query')
showParents = !(url.searchParams.get('hide-parents') is '1')
main = null

descriptionInput = null
queryInput = null

selectedTags = []

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

getLinkMarkdown = (url, name) ->
    "[#{(await name) or 'enter link description here'}](#{url})"

getParamString = (query, showParents) ->
    params = {}
    if tpQuery then params.query = tpQuery
    if !showParents then params['hide-parents'] = '1'

    result = (new URLSearchParams params).toString()
    if result then result = "?#{result}"
    return result

getLinkUrl = (locator, tpQuery, showParents) ->
    paramString = getParamString(tpQuery, showParents) || ''
    "#{location.origin}/#{locator.full}#{paramString}"

`$: linkUrl = getLinkUrl(locator, tpQuery, showParents)`

onMount () ->
    await rendered
    jumpToHash()


linkMarkdown = null
`$: linkMarkdown = getLinkMarkdown(linkUrl, name);`

rendered = null
`$: rendered = render(text, tpQuery, selectedTags, showParents)`

</script>

<svelte:window
    on:hashchange={jumpToHash}
/>

<template lang=pug>
    header('spellcheck=false')
        div.source: h1 Source: {@html source}
        details('bind:open' 'on:toggle={onToggle}')
            summary { open ? 'Hide' : 'Show' } advanced controls
            div.options
                h2 Options
                div.label Description:
                input('bind:this={descriptionInput}' 'bind:value={name}' placeholder='Link Description')
            div.links
                h2 Shareable Links
                ClipboardInput(label='Text' value='{linkUrl}')
                +await('linkMarkdown then linkMarkdown')
                    ClipboardInput(label='Markdown' value='{linkMarkdown}')
                ClipboardLink(label='HTML' href='{linkUrl}' text="{name || 'link'}")

    div.controls-container
        div.controls('spellcheck=false')
            span.taskpaper-query.inner-addon.left-addon
                i.fas.fa-search
                input('bind:this={queryInput}' 'bind:value={tpQuery}' placeholder='TaskPaper Query')
            span: label
                input('type=checkbox' 'bind:checked={showParents}')
                span Show Parents

            +await('rendered then rendered')
                span.result-count {@html rendered.count}
                span.copy-button: button('on:click={onClick}')
                    i.fas.fa-clipboard
                    | Copy to clipboard
        div.sidebar-main-container
            div.sidebar-container
                div.sidebar
                    +await('rendered then rendered')
                        +each('rendered.tags as { key, name, count }')
                            div.tags
                                input('type=checkbox' id='tag-{name}' 'bind:group={selectedTags}' value='{key}')
                                label(for='tag-{name}') {name} {count}
            main('bind:this={main}')
                +await('rendered')
                    div Loading...
                    +then('rendered')
                        div.content {@html rendered.html}
                    +catch('error')
                    p {error}
</template>


<style global>
    .tags input[type=checkbox] {
        display: none
    }

    input:checked + label {
        font-weight: bold;
    }

    .sidebar-main-container {
        display: flex;
    }

    .sidebar {
        width: 200px;
        height: 400px;
        position: sticky;
        top: 34px;

        overflow-y: scroll;
    }

    header {
        background-color: #eee8d5;
        color: #657b83;
    }

    header > div {
        padding: 0 8px;
    }

    header h1, header h2, header h3 {
        margin: 0;
    }

    header details {
        padding: 0 8px;
    }

    .options {
        margin-bottom: 20px;
    }

    main {
        padding: 8px;
        background-color: #fdf6e3;
        color: #657b83;
    }

    .links pre {
        margin: 0;
    }

    .links label {
        margin-bottom: 10px;
    }

    .links button {
        width: 110px;
    }
    .controls {
        display: flex;
        align-items: baseline;

        border-bottom: 1px dotted #586e75;
        background-color: #eee8d5;
        padding: 2px 8px;

        position: sticky;
        top: 0;

        z-index: 9999;
    }

    .controls > span {
        margin-right: 8px;
        font-size: 14px;
    }

    .controls .result-count {
        margin-left: auto;
        color: #93a1a1;
    }

    .controls .copy-button {
        margin-right: 0;
    }

    .controls i{
        padding-right: 6px;
    }

    .controls button {
        padding: 2px 8px;
        border-radius: 4px;
        margin-bottom: 2px;
    }

    header details summary,
    .taskpaper-query input:focus {
        outline: none;
    }

    .taskpaper-query {
        display: inline-block;
    }

    .options input,
    .taskpaper-query input {
        padding: 2px 2px;
        font-size: 14px;
        margin-bottom: 4px;
    }

    .taskpaper-query input {
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

    .controls label {
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

    .content ul,
    .content li,
    .content p {
        list-style-type: none;
        margin: .38em auto;
    }
</style>

