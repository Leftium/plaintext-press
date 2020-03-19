import * as birch from 'birch-outline'
import neatLinkify from './neat-linkify.coffee'

export default renderTaskpaperOutline  = (text, itemPath='*', showParents=true, allContext) ->
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
    results = outline.evaluateItemPath(itemPath)

    for item in results
        item.directResult = true

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
    if itemPath is '*' then resultCount = ''

    return { html, count: resultCount }

