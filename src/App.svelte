<script type='text/coffeescript'>
    import Main from './Main.svelte'
    import View from './View.svelte'

    parseBoolean = (value) ->
        falsey = /^(?:f(?:alse)?|no?|0+)$/i
        !falsey.test(value) and !!value

    DEV_MODE = parseBoolean(new URL(location).searchParams.get('dev'))

    TEST_URLS = [
        ['View: urlencoded', '/Hello+World']
        ['View: https (patagonia)', '/https://www.dropbox.com/s/1g5qrmfinno8a5j/patagonia.taskpaper?dl=0']
        ['View: lzstring', '/lzstring:C4UwzsB0wIZg1gBxokAnA9ABTQewFYgDGwAggFwAEAArAOYAUA7gJbAAWlAbjADYCuIAJQAoAJABaSgBU48AIyVWHGgCMYaEPUosAdpQC2LACbHeIcdQYA5GAZDmwYSvSFK2nXblCUYAM1A0HWBxKVkEACZ3FTB+VQlEPEIScTEAUQNEYABPHAJiYHIRPOTgACEiyUosXhg9FzkAZnEauv0vUCA']
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
+if('DEV_MODE')
    hr
    h2 App.svelte starts here (i.e. anthhing below here is only here for developers):
    ul
        +each('TEST_URLS as tu')
            li: a(href='{tu[1]}' title='{tu[1]}') {tu[0]}
</template>

<style>

</style>
