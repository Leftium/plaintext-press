<script type='text/coffeescript'>
export href = null
export text = null
export label = ''
export target = '_self'

link = null

handleCopyLink = (event) ->
    html = link.innerHTML
    listener = (e) ->
        e.clipboardData.setData 'text/html', html
        e.clipboardData.setData 'text/plain', html
        e.preventDefault()

    document.addEventListener 'copy', listener
    document.execCommand 'copy'
    document.removeEventListener 'copy', listener

</script>


<style>

button {
    border-top-right-radius: 0;
    border-bottom-right-radius: 0;
}

.linkbox {
    border: 1px solid rgba(147,128,108,.25);
    margin-top: 4px;
    margin-bottom: 0.5em;

    border-top-left-radius: 0;
    border-bottom-left-radius: 0;
    border-top-right-radius: 2px;
    border-bottom-right-radius: 2px;

    padding: 4px;
}

.InputAddOn {
    display: flex;
}

.InputAddOn-field,
.InputAddOn-item {
    border: 1px solid rgba(147,128,108,.25);
    padding: 20.5em, 2.75em;
}

.InputAddOn-field {
  flex: 1;
  /* field styles */

}

.InputAddOn-field:not(:first-child) {
    border-left: 0;
}

.InputAddOn-item {
    /* item styles */
    color: #666666;
    font: inherit;
    font-weight: normal;

    margin-top: 4px;
    margin-bottom: 0.5em;
}

a {
    text-decoration: underline;
}
</style>


<div class='InputAddOn'>
    <button class='InputAddOn-item'
            on:click={handleCopyLink}>
        <i class='fas fa-clipboard decoration-fa'></i>
        {label}
    </button>
    <div class='linkbox InputAddOn-field'
         bind:this={link}>
        <a href={href} target={target}>{text}</a>
    </div>
</div>

