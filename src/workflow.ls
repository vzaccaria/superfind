
require! 'alfredo'
require! 'winston'
path    = require('path')
_       = require('underscore')
_.str   = require('underscore.string');
moment  = require 'moment'
shelljs = require('shelljs')
clip    = require('cliparoo')
escape  = require('shell-escape');

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

winston.add(winston.transports.File, { filename: '/Users/zaccaria/.alfred-inspect.log', level: 'silly', json: false, prettyPrint: true });
winston.remove(winston.transports.Console);

winston.info process.argv


args = process.argv[2]
args = _.words(args)

category = (w) ->
    c = w.charAt(0)
    cat = 
        | c == '#'                  => { value: w, type: 'word'  }
        | c == '.'                  => { value: w, type: 'type'  }
        | c == '<' or c == '>'      => { value: w, type: 'date'  }
        | c == '+'                  => { value: w, type: 'force' }
        | otherwise                 => { value: w, type: 'name'  }

categorized = [ category(w) for w in args ]

f-words = _.map(_.filter(categorized, (.type == 'word')), (.value))
f-types = _.map(_.filter(categorized, (.type == 'type')), (.value))
f-name  = _.map(_.filter(categorized, (.type == 'name')), (.value))
f-dates = _.map(_.filter(categorized, (.type == 'date')), (.value))

web-docs    = [ \.html \.pdf ]
gen-docs    = [ \.doc \.docx \.pages \.md ]
pres-docs   = [ \.ppt \.pptx \.key ]

all-docs = web-docs ++ gen-docs ++ pres-docs 
if f-types.length == 0
    f-types := all-docs 

winston.info f-dates


to-from-date = (op, number, unit) ->
    if op == '<'
        op := '>'
    else 
        op := '<'
    number = parseInt(number)
    m = moment().subtract(number, unit).toISOString()
    return "kMDItemFSContentChangeDate#{op}$time.iso(#m)"

get-time-reference = (txt) ->
    op = txt.charAt(0)
    txt = txt.slice(1)
    num = 7 
    unit = 'days'

    winston.info 'Getting time reference'
    winston.info txt

    if _.endsWith(txt, 'd')
        num = txt.substring(0, txt.length - 1) 
        unit = 'days'
        return to-from-date(op, num, unit)

    if _.endsWith(txt, 'y')
        num = txt.substring(0, txt.length - 1) 
        unit = 'years'
        return to-from-date(op, num, unit)

    if _.endsWith(txt, 'm')
        num = txt.substring(0, txt.length - 1) 
        unit = 'months'
        return to-from-date(op, num, unit)

    if _.endsWith(txt, 'h')
        num = txt.substring(0, txt.length - 1) 
        unit = 'hours'
        return to-from-date(op, num, unit)

    return undefined

fire = _.any(f-words ++ f-name, (.length > 4)) or _.any(categorized, (.type== "force"))

q-contents = [ "(kMDItemTextContent=\"#{txt.slice(1)}\"wc)" for txt in f-words ] * ' && '
winston.info q-contents

q-types    = ([ "kMDItemFSName=\"*.#{txt.slice(1)}\"wc"  for txt in f-types ] ++ [ "kMDItemKind=folder"])             * ' || '
winston.info q-types

q-name     = [ "kMDItemFSName=\"*#{txt}*\"wc" for txt in f-name ] * ' || '
winston.info q-name 

q-dates    = [ get-time-reference(txt) for txt in f-dates ] * ' && '
winston.info q-dates


query = _.filter [q-contents, q-types, q-name, q-dates], ->
    it != ""

query = [ "(#q)" for q in query ] * ' && '

files = []

pquery = "'#query'"
shelljs.exec "echo #pquery | pbcopy", {+async, +silent}, ->

if fire 
    query = "mdfind #pquery -onlyin ~"
    winston.info "Executing query #query"
    child = shelljs.exec query, {+async, +silent}
    child.stdout.on "data", (output) ->
            winston.info output
            files := _.lines(output)
            show = files.map ->

                type = path.extname(it).slice(1)

                item = 
                    title: path.basename(it)
                    subtitle: it
                    arg: it
                    valid: true

                item.icon = 
                    '@': 
                        type: 'fileicon'
                    '#': "#it"


                new alfredo.Item(item)

            alfredo.feedback(show)
        # alfredo.feedback(new alfredo.Item(title: "sorry", valid: true))

else 
    alfredo.feedback(new alfredo.Item(title: "Try a longer term to search for", valid: false))
