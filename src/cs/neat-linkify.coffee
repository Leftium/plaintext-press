import * as linkify from 'linkifyjs'
import linkifyHtml from 'linkifyjs/html'


makeLinkifyOptions = (options) ->
    attributes: (href) ->
        attributes =
            title: href
    format: (value, type) ->
        if type is 'email' then return value.replace /mailto:/i, ''


        # Soft limit; sum of required components can exceed this number.
        maxLength =     options?.maxLength     or 30
        # Minimum length for required components.
        minLength =     options?.minLength     or 20
        stripFilename = options?.stripFilename or false
        stripSearch =   options?.stripSearch   or false

        # Shorten string to length, with ellipses to indicate part removed.
        truncate = (string, length) ->
            if string.length > length
                string = string[0...length-1] + '…'
            string

        # Form URL from sections, adding seperators where needed.
        combineSections = (s) ->
            dot1 = dot2 = slash1 = slash2 = slash3 = slash4 = ''
            if s.sub and s.domain then dot1 = '.'
            if s.domain and s.tld then dot2 = '.'
            if s.head then slash1 = '/'
            if s.body then slash2 = '/'
            if s.tail then slash3 = '/'
            if s.filename then slash4 = '/'

            displayUrl = "#{s.sub}#{dot1}#{s.domain}#{dot2}#{s.tld}#{slash1}" +
                         "#{s.head}#{slash2}#{s.body}#{slash3}#{s.tail}"      +
                         "#{slash4}#{s.filename}#{s.search}#{s.hash}"

        # Get important parts of URL. (Skip protocol, port, search, etc...)
        try
            urlObject = new URL value
        catch
            value = 'https:' + value
            urlObject = new URL value

        {hostname, pathname, hash, search} = urlObject
        currentHostname = (new URL location).hostname

        if stripSearch then search = ''

        # Hide 'www.' subdomain.
        hostname = hostname.replace /^www\./i, ''
        parts = hostname.split '.'

        tld = parts.pop()
        domain = parts.pop() or ''
        sub = parts.join '.'

        # Remove leading/trailing '/' from path before splitting.
        pathname = pathname.replace ///^/|/$///g, ''
        parts = pathname.split '/'
        filename = parts.pop()

        # If no filename, last directory segment is parsed as filename.
        if filename.indexOf('.') is -1
            parts.push filename
            filename = ''

        # If path "head" is only character, add the next segment.
        head = parts.shift() or ''
        if head.length is 1 and (parts[0])
            head = "#{head}/#{parts.shift()}"

        tail = parts.pop() or ''
        body = parts.join '/'

        # 's' for url sections.
        s = {sub, domain, tld, head, body, tail, filename, search, hash}

        displayUrl = combineSections s

        # First, try reducing URL search parameters.
        excess = displayUrl.length - maxLength
        if s.search and excess > 0
            targetLength = s.search.length - excess
            if targetLength > 2
                s.search = truncate s.search, targetLength
            else
                s.search = '?…'

        # Then try reducing the 'body' of the path.
        excess = displayUrl.length - maxLength
        if s.body and excess > 0
            targetLength = s.body.length - excess
            if targetLength > 2
                # Ensure entire first word is kept unless it's too long.
                parts = body.split /[-_]/
                firstWordLength = Math.min(parts[0].length+2, 20)
                targetLength = Math.max(targetLength, firstWordLength)
                s.body = truncate s.body, targetLength
            else
                s.body = '\u22EF'  # Midline horizontal ellipsis ⋯
        displayUrl = combineSections s

        # Helper method to reduce boilerplate.
        # Uses/modifies varibles from parent scope: s, displayUrl, maxLength
        crunchDisplayUrl = (sectionName, minLength=20) ->
            excess = displayUrl.length - maxLength
            if s[sectionName] and excess > 0
                targetLength = s[sectionName].length - excess
                targetLength = Math.max(targetLength, minLength)
                s[sectionName] = truncate s[sectionName], targetLength
            displayUrl = combineSections s

        # Continue trying to reduce these sections
        # in order of insignificance.
        crunchDisplayUrl 'tail',     minLength
        crunchDisplayUrl 'head',     minLength
        crunchDisplayUrl 'filename', minLength
        crunchDisplayUrl 'sub',      minLength
        crunchDisplayUrl 'hash',     minLength
        crunchDisplayUrl 'tld',      minLength
        crunchDisplayUrl 'domain',   minLength

        # Finally, try removing the 'tail' and 'head' of the path
        # if there is also a filename.
        if (displayUrl.length > maxLength) and (s.filename)
            s.tail = '\u22EF'  # Midline horizontal ellipsis ⋯
            crunchDisplayUrl 'tail', minLength

        if (displayUrl.length > maxLength) and (s.filename)
            s.head = '\u22EF'  # Midline horizontal ellipsis ⋯
            crunchDisplayUrl 'head', minLength

        # Combine adjacent ellipses into one.
        displayUrl = displayUrl.replace ///\u22EF(/\u22EF)+///, '\u22EF'
        return displayUrl


export default neatLinkify = (html, options = {}) ->
    linkifyHtml html, makeLinkifyOptions(options)

