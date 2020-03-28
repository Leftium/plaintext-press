<script type='text/coffeescript'>
import { onMount } from 'svelte'

import lzString from 'lz-string'

import ClipboardInput from './components/ClipboardInput.svelte'
import ClipboardLink  from './components/ClipboardLink.svelte'

import renderTaskpaper from './cs/render-taskpaper.coffee'
import neatLinkify from './cs/neat-linkify.coffee'

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

render = (text, query, selectedTags, contextLevel) ->
    {html, rest...} = await renderTaskpaper text, query, selectedTags, contextLevel

    if html
        tmpDiv = document.createElement 'div'
        tmpDiv.innerHTML = html

        listItems = tmpDiv.querySelectorAll 'li'

        for listItem in listItems
            if matches = listItem.innerText.match /(^|\s)#([^#\s]*)/i
                listItem.id = matches[2].toLowerCase()

        html = tmpDiv.innerHTML

    return {html, rest...}

tagIsVisible = (key, name, tagFilter) ->
    if (tagFilter is '') or (name.toLowerCase().match(tagFilter)) or (key in selectedTags)
        return true



jumpToHash = () ->
    if location.hash and target = document.querySelector(location.hash)
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

tagFilter = ''

main = null

contextLevel = url.searchParams.get('context-level') or 0
contextLevelDescription = (level) ->
    text = switch
        when level < 0
            'Hide Parents'
        when level is 0
            'Show All'
        else
            "#{level} deep"
    "Context: #{text}"


descriptionInput = null
queryInput = null

selectedTags = []


getLinkMarkdown = (url, name) ->
    "[#{(await name) or 'enter link description here'}](#{url})"

getParamString = (query, contextLevel) ->
    params = {}
    if tpQuery then params.query = tpQuery
    if contextLevel then params['context-level'] = contextLevel

    result = (new URLSearchParams params).toString()
    if result then result = "?#{result}"
    return result

getLinkUrl = (locator, tpQuery, contextLevel) ->
    paramString = getParamString(tpQuery, contextLevel) || ''
    "#{location.origin}/#{locator.full}#{paramString}"

`$: linkUrl = getLinkUrl(locator, tpQuery, contextLevel)`


locator = parseLocator location.pathname[1..].replace(/\/+$/, '')
{name, text} = fetchLocator locator

linkMarkdown = null
`$: linkMarkdown = getLinkMarkdown(linkUrl, name);`

rendered = null
`$: rendered = render(text, tpQuery, selectedTags, contextLevel)`



switch locator.type
    when 'lzstring', 'urlencoded'
        source = 'embedded in URL'
        if name then source = "#{name} (#{source})"
    when 'local'
        source = "#{name} (local browser)"
    else
        source = neatLinkify locator.full


onTag = (e) ->
    delayedFunction = () ->
        if e.target.checked
            contextLevel = 1
        else
            if selectedTags.length is 0
                contextLevel = 0
    setTimeout delayedFunction, 0


onClickClearAll = (e) ->
    selectedTags = []
    contextLevel = 0


onMount () ->
    await rendered
    jumpToHash()



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
            div
                span.context-buttons
                    button('on:click={() => contextLevel = Math.max(contextLevel-1, -1)}') &lt;
                    button('on:click={() => contextLevel++}') &gt;
                span {contextLevelDescription(contextLevel)}

            +await('rendered then rendered')
                span.result-count {@html rendered.count}
                span.copy-button: button('on:click={onClick}')
                    i.fas.fa-clipboard
                    | Copy to clipboard
        div.sidebar-main-container
            div.sidebar-container('spellcheck=false')
                div.sidebar
                    div.tag-controls
                        h2 Tags
                        input('bind:value={tagFilter}' placeholder='Tag Filter')
                        button('on:click={onClickClearAll}') Clear All Tags
                    div.tag-container
                        +await('rendered then rendered')
                            +each('rendered.tags as { key, name, count }')
                                +if('tagIsVisible(key, name, tagFilter)')
                                    div.tag
                                        input('on:change={onTag}' 'type=checkbox' id='tag-{name}' 'bind:group={selectedTags}' value='{key}')
                                        label(for='tag-{name}'): span.label
                                            span.tag-name {name}
                                            span.tag-count {count}
            main('bind:this={main}')
                +await('rendered')
                    div Loading...
                    +then('rendered')
                        div.content {@html rendered.html}
                    +catch('error')
                    p {error}
</template>


<style global>
    .tag-controls {
        padding: 8px;
    }

    .label {
        display: flex;
        justify-content: space-between;
        padding: 0 8px;
    }
    .tag-count {
        font-size: 12px;
        opacity: 50%;
    }

    .tag-container {
        height: 300px;
        overflow-y: scroll;
    }

    .controls span {
        font-size: 14px;
    }
    .tag input[type=checkbox] {
        display: none
    }

    input:checked + label {
        font-weight: bold;
    }

    .sidebar-main-container {
        display: flex;
        background-color: #eee8d5
    }

    .sidebar {
        width: 200px;
        height: 400px;
        position: sticky;
        top: 34px;
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
        width: 100%;
        min-height: 100vh;
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

    .sidebar button,
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


    .context-buttons button {
        padding: 2px;
    }

    .controls button:focus {
        border-color: #ccc;
    }

    .context-buttons :first-child {
        border-top-right-radius: 0;
        border-bottom-right-radius: 0;
        border-right: .5px solid #ccc;
    }

    .context-buttons :last-child {
        border-top-left-radius: 0;
        border-bottom-left-radius: 0;
        border-left: .5px solid #ccc;
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

    .content [show='result'] { }
    .content [show='context'] { opacity: 22%; }
    .content [show='hidden'] { display:none }

    .content ul,
    .content li,
    .content p {
        list-style-type: none;
        margin: .38em auto;
    }
</style>

