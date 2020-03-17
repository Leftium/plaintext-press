<script type='text/coffeescript'>
    import Main from './main.svelte'
    import View from './view.svelte'

    TEST_URLS = [
        ['View: urlencoded', '/Hello+World']
        ['View: https', '/https://www.dropbox.com/s/0dh0fivnoi8am7z/README.taskpaper?dl=0']
        ['View: lzstring', '/lzstring:DYLwzgLgTglgdgcwHQQIZgNYAdVYKZQD0AKgBYxgAEFlEpelOAnsAPaoAmlAZq1JajiVQkWIiSUyNGnQbM2nHnwFCR0eMiA']
        ['View: urlencoded, w/ link UI ', '/Hello+World?links=1']
        ['','']
        ['Main: bare', '/']
        ['Main: urlencoded', '/?content=Hello+World']
        ['Main: urlencoded, buffer', '/?content=Hello+World&buffer=new.taskpaper']
        ['Main: no content, buffer', '/?buffer=new.taskpaper']
    ]

    component = Main

    if location.pathname isnt '/'
        component = View

</script>


<svelte:component this={component} />


<template lang=pug>
hr
h2 App.svelte starts here:
ul
    +each('TEST_URLS as tu')
        li: a(href='{tu[1]}' title='{tu[1]}') {tu[0]}
</template>

<style>

</style>
