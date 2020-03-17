<script type='text/coffeescript'>
    import Main from './main.svelte'
    import View from './view.svelte'

    TEST_URLS = [
        ['View, embedded content', '/Hello+World']
        ['View, embedded content with share UI', '/Hello+World?links=1']
        ['','']
        ['Main, bare', '/']
        ['Main, embedded content', '/?content=Hello+World']
        ['Main, embedded content, buffer', '/?content=Hello+World&buffer=new.taskpaper']
        ['Main, buffer', '/?buffer=new.taskpaper']
    ]

    component = Main

    if location.pathname isnt '/'
        component = View

    url = location.href
    console.log location
</script>


<svelte:component this={component} />


<template lang=pug>
hr
h2 App.svelte starts here:
h3 Url: {url}
ul
    +each('TEST_URLS as tu')
        li: a(href='{tu[1]}' title='{tu[1]}') {tu[0]}
</template>

<style>

</style>
