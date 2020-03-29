<script type='text/coffeescript'>
# Progress Nav based on https://lab.hakim.se/progress-nav/

import { onMount, tick } from 'svelte'

toc = null
tocPath = null
tocItems = []

# Factor of screen size that the element must cross
# before it's considered visible
TOP_MARGIN = 0
BOTTOM_MARGIN = 0

pathLength = null

drawPath = () ->
    tocItems = [].slice.call( toc.querySelectorAll( 'li' ) )


    # Cache element references and measurements
    tocItems = tocItems.map ( item ) ->
        anchor = item.querySelector( 'a' )
        target = document.getElementById( anchor.getAttribute( 'href' ).replace(/.*#/, '') )

        return object =
            listItem: item
            anchor: anchor
            target: target

    # Remove missing targets
    tocItems = tocItems.filter ( item ) ->
        if item.target.getAttribute('show') is 'hidden'
            return false
        return !!item.target

    path = []
    pathIndent = null

    tocItems.forEach ( item, i ) ->

        x = item.anchor.offsetLeft - 5
        y = item.anchor.offsetTop
        height = item.anchor.offsetHeight

        if i is 0
            path.push( 'M', x, y, 'L', x, y + height )
            item.pathStart = tocPath.getTotalLength() or 0
        else
             # Draw an additional line when there's a change in
             # indent levels
             if pathIndent isnt x then path.push( 'L', pathIndent, y )

             path.push( 'L', x, y )

             # Set the current path so that we can measure it
             tocPath.setAttribute( 'd', path.join( ' ' ) )
             item.pathStart = tocPath.getTotalLength() or 0

             path.push( 'L', x, y + height )

        pathIndent = x

        tocPath.setAttribute( 'd', path.join( ' ' ) )
        item.pathEnd = tocPath.getTotalLength()

    pathLength = tocPath.getTotalLength()

    sync()



sync = () ->
    if not tocItems.length then return

    windowHeight = window.innerHeight

    pathStart = Number.MAX_VALUE
    pathEnd = 0

    visibleItems = 0
    tocItems.forEach ( item, i ) ->

        {top, bottom} = item.target.getBoundingClientRect()

        if nextItem = tocItems[i + 1]
            bottom = nextItem.target.getBoundingClientRect().top
        else
            bottom = Infinity

        if (bottom > windowHeight * TOP_MARGIN) and (top < windowHeight * ( 1 - BOTTOM_MARGIN ) )
            pathStart = Math.min( item.pathStart, pathStart )
            pathEnd = Math.max( item.pathEnd, pathEnd )

            visibleItems += 1

            item.listItem.classList.add( 'visible' )
        else
            item.listItem.classList.remove( 'visible' )

      # Specify the visible path or hide the path altogether
      # if there are no visible items
      if visibleItems > 0 and (pathStart < pathEnd )
          tocPath.setAttribute( 'stroke-dashoffset', '1' )
          tocPath.setAttribute( 'stroke-dasharray', "1, #{pathStart}, #{pathEnd - pathStart}, #{pathLength}" )
          tocPath.setAttribute( 'opacity', 1 )
      else
          tocPath.setAttribute( 'opacity', 0 );



onMount () ->
    # Wait for contents to be rendered first so we can find the id's of
    # of elements with jump links/
    await tick()

    drawPath()

</script>


<style global>
    .toc {
      left: 3em;
      top: 5em;
      padding: 1em;
      width: 14em;
      line-height: 2;
    }

    .toc ul {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .toc ul ul { padding-left: 2em; }

    .toc li a {
      display: inline-block;
      color: #aaa;
      text-decoration: none;
      -webkit-transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
      transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
    }

    .toc li.visible > a {
      color: #111;
      -webkit-transform: translate(5px);
      transform: translate(5px);
    }

    .toc-marker {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: -1;
    }

    .toc-marker path {
      -webkit-transition: all 0.3s ease;
      transition: all 0.3s ease;
    }


</style>

<svelte:window
    on:resize={drawPath}
    on:scroll={sync}
/>

<nav class='toc' bind:this={toc}>
    <slot></slot>
</nav>
<svg class="toc-marker" width="200" height="200" xmlns="http://www.w3.org/2000/svg">
    <path bind:this={tocPath} stroke="#444" stroke-width="3" fill="transparent" stroke-dasharray="0, 0, 0, 1000" stroke-linecap="round" stroke-linejoin="round" transform="translate(-0.5, -0.5)" />
</svg>

