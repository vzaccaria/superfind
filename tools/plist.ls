
_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')
sh              = require('shelljs')
os              = require('os')
shelljs         = sh
gen-uid         = require 'gen-uid'
debug           = require('debug')('plist')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

pjson = require(__dirname+"/../package")

# "/usr/local/bin/node index.js \"{query}\"",

gen-script-filter = (name, script, png-icon-file) ->
    dname = _.underscored(name)    
    debug "Generating #name, #script, icon: #png-icon-file"

    f = {
            config:
                argumenttype: 1,
                keyword: 'f',
                runningsubtext: "Running #name...",
                script: script 
                title: "#name..."
                type: 0,
                withspace: true            
            type: 'alfred.workflow.input.scriptfilter',
            uid: gen-uid.v4(),
            version: 0
    }

    if png-icon-file?
        shelljs.cp "#{__dirname}/../#{png-icon-file}", "#{__dirname}/../#{f.uid}.png"

    return f

gen-open-url = ->
    return {
            "config": {
            },
            "type": "alfred.workflow.action.openfile",
            "uid": gen-uid.v4()
    }

plist = (author, name, description, png-icon-file, url) ->
    dauthor = _.underscored(author)
    dname = _.underscored(name)

    url ?= "https://your-git-address-here"

    w = {
        bundleid    : "com.#dauthor.#dname"
        createdby   : author
        description : description
        disabled    : false
        name        : name
        webaddress  : url
        uid: gen-uid.v4()
    }

    if png-icon-file?
        shelljs.cp "#{__dirname}/../#{png-icon-file}", "#{__dirname}/../icon.png"

    return w

add-flow = (src, dest, plist) ->
    plist.objects ?= []
    plist.objects.push src
    plist.objects.push dest
    plist.connections ?= {}
    plist.connections[src.uid] = [
        * destinationuid: dest.uid
          modifiers: 0
          modifiersubtext: ""
        ]
    plist.uidata ?= {}
    plist.uidata[src.uid] = { ypos: 10 }
    plist.uidata[dest.uid] = { ypos: 10 }
    return plist

_module = ->

    write-plist = ->

        p    = plist(pjson.author, pjson.name, pjson.description, pjson["workflow-icon"])
        src  = gen-script-filter pjson.name, "/usr/local/bin/node index.js \"{query}\"", pjson["filter-icon"]
        dest = gen-open-url()
        add-flow src, dest, p
        pl = require('plist').build p

        debug "Writing file"
        debug pl
        fs.writeFileSync(__dirname+"/../info.plist", pl, 'utf8')

    read-plist = ->
        pl = fs.readFileSync(it, 'utf8')
        return require('plist').parse(pl)
          
    iface = { 
        write-plist: write-plist
        read-plist: read-plist
    }
  
    return iface
 
module.exports = _module()

