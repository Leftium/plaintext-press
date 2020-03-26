import * as birch from 'birch-outline'
import neatLinkify from './neat-linkify.coffee'

export default renderTaskpaperOutline  = (text, itemPath='*', selectedTags=[], showParents=true, allContext) ->
    renderItem = (item) ->
        itemLI = document.createElement('li')
        for attribute in item.attributeNames
             itemLI.setAttribute attribute, item.getAttribute(attribute)

        indentation = ''
        if showParents
            for n in [0...item.depth-1]
                indentation += '\t'

        itemLI.setAttribute 'depth', item.depth


        if item.directResult
            itemLI.setAttribute 'is-context', 'false'
        else
            itemLI.setAttribute 'is-context', 'true'

        if allContext
            itemLI.setAttribute 'is-context', 'true'


        itemLI.innerHTML = indentation + item.bodyHighlightedAttributedString
                                             .toInlineBMLString() or '&nbsp;'
        return neatLinkify itemLI.outerHTML

    outline = new birchoutline.Outline.createTaskPaperOutline(await text)

    # Count tags
    tags = {}
    for item in outline.items
        for tagName in item.attributeNames
            if tagName in ['data-type', 'indent'] then continue
            tagName = tagName.replace 'data-', ''
            key = tagName.toLowerCase()

            if tags[key]
                tags[key].count++
            else
                tags[key] =
                    key: key
                    name: tagName or '@'
                    count : 1

    # Sort by count, then alphabetically.
    sortedKeys = Object.keys(tags).sort().sort (a, b) ->
        tags[b].count - tags[a].count
    sortedTags = (tags[k] for k in sortedKeys)

    results = outline.evaluateItemPath(itemPath)

    for item in results
        item.hasTag = false
        for tagName in item.attributeNames
            if tagName in ['data-type', 'indent'] then continue
            tagName = tagName.replace 'data-', ''
            key = tagName.toLowerCase()
            if (key in selectedTags) or (selectedTags.length is 0)
                item.directResult = true
                item.hasTag = true
                break

    results = results.filter (item) -> item.hasTag

    resultsToRender = results

    # Add parent items, for context.
    if showParents
        knownParents =
            'Birch': true

        resultsToRender = []

        addItem = (item) ->
            knownParents[item.id] = true
            if item.parent and not knownParents[item.parent.id]
                addItem(item.parent)

            resultsToRender.push item

        for item in results
            addItem item


    html = ''
    for item in resultsToRender
        html += renderItem item

    resultCount = "#{results.length} result"
    if results.length isnt 1 then resultCount += 's'
    if (itemPath is '*') and (selectedTags.length is 0) then resultCount = ''

    return { html, count: resultCount, tags: sortedTags }

