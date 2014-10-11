
require! 'alfredo'
require! 'winston'
path    = require('path')
_       = require('underscore')
_.str   = require('underscore.string');
moment  = require 'moment'
shelljs = require('shelljs')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

winston.add(winston.transports.File, { filename: '/Users/zaccaria/.alfred-inspect.log', level: 'silly', json: false, prettyPrint: true });
winston.remove(winston.transports.Console);

winston.info process.argv


args = process.argv[2]

args = _.words(args)

words = _.reject args, -> 
    c = it.charAt(0)
    return (c == "." or c== "<" or c == ">" or c=='#')

f-types = _.filter args, ->
    c = it.charAt(0)
    return c == "."

f-name = _.filter args, ->
    c = it.charAt(0)
    return c == '#'

f-dates = _.filter args, ->
    c = it.charAt(0)
    return (c == '>' or c == '<')

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

fire = _.any(words, -> it.length > 4) or _.any(f-name, -> it.length > 4)

q-contents = [ "(kMDItemTextContent=\"#txt\"cd || kMDItemFSName=*#txt*)" for txt in words ] * ' && '
winston.info q-contents

q-types    = [ "kMDItemFSName=*#txt"  for txt in f-types ]              * ' || '
winston.info q-types

q-name     = [ "kMDItemFSName=*#{txt.slice(1)}*" for txt in f-name ]    * ' || '
winston.info q-name 

q-dates    = [ get-time-reference(txt) for txt in f-dates ]             * ' && '
winston.info q-dates


query = _.filter [q-contents, q-types, q-name, q-dates], ->
    it != ""

query = query * ' && '

if fire 
    winston.info "Executing query #query"
    shelljs.exec "mdfind '#query' -onlyin ~", {+silent}, (err, output) ->
        if not err
            files = _.lines(output)
            files = _.first(files, 30)
            files = files.map ->

                type = path.extname(it).slice(1)

                item = 
                    title: path.basename(it)
                    subtitle: it
                    arg: it
                    valid: true

                item.icon = 
                    '@': 
                        type: 'filetype'
                    '#': "public.#type"


                new alfredo.Item(item)

            alfredo.feedback(files)
        # alfredo.feedback(new alfredo.Item(title: "sorry", valid: true))

else 
    alfredo.feedback(new alfredo.Item(title: "sorry, try a longer term to look for", valid: false))
