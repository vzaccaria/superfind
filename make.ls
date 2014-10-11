#!/usr/bin/env livescript

{ parse } = require('newmake')

name = "lib"
srv-dst = "#name"
srv-src = "src"

parse ->
    @collect "all", -> [
        @collect "lib", -> 
            @toDir "#srv-dst", { strip: "#srv-src" }, [ 
                    -> @copy "#srv-src/**/*.js"
                    -> @livescript "#srv-src/**/*.ls"
                    ]

    ]
    @collect "clean", -> [
        @remove-all-targets()
        @on-clean "rm -rf #name"
        @on-clean "rm -f *.png"
        @on-clean "rm -f *.alfredworkflow"
    ]

        

