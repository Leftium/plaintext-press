<script type='text/coffeescript'>

stickyElement = null
container = null
beforeHeight = Infinity

handleScroll = (event) ->
    if window.pageYOffset > beforeHeight
        stickyElement.classList.add 'sticky'
        container.classList.add 'has-sticky'
    else
        stickyElement.classList.remove 'sticky'
        container.classList.remove 'has-sticky'
</script>

<style>

/* The sticky class is added to the header with JS when it reaches its scroll position */
:global(.sticky) {
    position: fixed !important;
    top: 0;
    width: 100%;
    z-index: 1000;
}

/* Add some top padding to the page content to prevent sudden quick movement (as the header gets a new position at the top of the page (position:fixed and top:0) */
:global(.has-sticky + main) {
    padding-top: 34px;
}

</style>

<svelte:window on:scroll={handleScroll}/>

<div class='sticky-header' bind:this={container}>
    <div bind:clientHeight={beforeHeight}>
        <slot name='beforeElement'></slot>
    </div>
    <div bind:this={stickyElement}>
        <slot name='stickyElement'></slot>
    </div>
</div>

