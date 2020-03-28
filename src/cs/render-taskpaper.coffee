import * as birch from 'birch-outline'
import neatLinkify from './neat-linkify.coffee'

export default renderTaskpaperOutline  = (text, itemPath, selectedTags=[], contextLevel=0) ->
    query = itemPath
    if not query
        if selectedTags.length
	    # All items.
            query = '*'
        else
            # All top level items.
            query = '/*'

    renderItem = (item) ->
        itemLI = document.createElement('li')
        for attribute in item.attributeNames
             itemLI.setAttribute attribute, item.getAttribute(attribute)

        indentation = ''
        if contextLevel >= 0
            for n in [0...item.depth-1]
                indentation += '\t'

        itemLI.setAttribute 'depth', item.depth

        switch
            when item.queryResult and item.tagResult
                itemLI.setAttribute 'show', 'result'
            when item.contextLevel is -1 and contextLevel isnt -1
	        # Parent item context.
                itemLI.setAttribute 'show', 'context'
            when contextLevel is 0 and item.contextLevel
	        # Show everything as context.
                itemLI.setAttribute 'show', 'context'
            when item.contextLevel > 0 and item.contextLevel < contextLevel
	        # Limit child context items.
                itemLI.setAttribute 'show', 'context'
            else
                itemLI.setAttribute 'show', 'hidden'

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
                    name: "@#{tagName}"
                    count : 1

    # Sort by count, then alphabetically.
    sortedKeys = Object.keys(tags).sort().sort (a, b) ->
        tags[b].count - tags[a].count
    sortedTags = (tags[k] for k in sortedKeys)


    queryResults = outline.evaluateItemPath(query)
    for item in queryResults
        item.queryResult = true

    if selectedTags.length
        tagQuery = ("#{tags[key].name}" for key in selectedTags).join(' or ')
    else
        tagQuery = '*'

    tagResults = outline.evaluateItemPath(tagQuery)

    for item in tagResults
        item.tagResult = true



    addParentContext = (item, level=0) ->
        if item.parent
            item.parent.contextLevel = level - 1
            addParentContext item.parent,  level - 1

    addChildContext = (item, level=0) ->
        for child in item.children
            child.contextLevel = level + 1
            addChildContext child, level + 1

    for item in outline.items
        if item.queryResult and item.tagResult
            item.contextLevel = 0
            addParentContext item
            addChildContext item





    html = ''
    numResults = 0
    for item in outline.items
        html += renderItem item
        if item.queryResult and item.tagResult
            numResults++

    resultCount = "#{numResults} result"
    if numResults isnt 1 then resultCount += 's'
    if not itemPath and (selectedTags.length is 0) then resultCount = ''

    return { html, count: resultCount, tags: sortedTags }

