(function(){
  var alfredo, winston, path, _, moment, shelljs, clip, escape, args, category, categorized, res$, i$, len$, w, fWords, fTypes, fName, fDates, webDocs, genDocs, presDocs, allDocs, toFromDate, getTimeReference, fire, qContents, txt, qTypes, qName, qDates, query, q, files, pquery, child, join$ = [].join;
  alfredo = require('alfredo');
  winston = require('winston');
  path = require('path');
  _ = require('underscore');
  _.str = require('underscore.string');
  moment = require('moment');
  shelljs = require('shelljs');
  clip = require('cliparoo');
  escape = require('shell-escape');
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  winston.add(winston.transports.File, {
    filename: '/Users/zaccaria/.alfred-inspect.log',
    level: 'silly',
    json: false,
    prettyPrint: true
  });
  winston.remove(winston.transports.Console);
  winston.info(process.argv);
  args = process.argv[2];
  args = _.words(args);
  category = function(w){
    var c, cat;
    c = w.charAt(0);
    return cat = (function(){
      switch (false) {
      case c !== '#':
        return {
          value: w,
          type: 'word'
        };
      case c !== '.':
        return {
          value: w,
          type: 'type'
        };
      case !(c === '<' || c === '>'):
        return {
          value: w,
          type: 'date'
        };
      case c !== '+':
        return {
          value: w,
          type: 'force'
        };
      default:
        return {
          value: w,
          type: 'name'
        };
      }
    }());
  };
  res$ = [];
  for (i$ = 0, len$ = args.length; i$ < len$; ++i$) {
    w = args[i$];
    res$.push(category(w));
  }
  categorized = res$;
  fWords = _.map(_.filter(categorized, function(it){
    return it.type === 'word';
  }), function(it){
    return it.value;
  });
  fTypes = _.map(_.filter(categorized, function(it){
    return it.type === 'type';
  }), function(it){
    return it.value;
  });
  fName = _.map(_.filter(categorized, function(it){
    return it.type === 'name';
  }), function(it){
    return it.value;
  });
  fDates = _.map(_.filter(categorized, function(it){
    return it.type === 'date';
  }), function(it){
    return it.value;
  });
  webDocs = ['.html', '.pdf'];
  genDocs = ['.doc', '.docx', '.pages', '.md'];
  presDocs = ['.ppt', '.pptx', '.key'];
  allDocs = webDocs.concat(genDocs, presDocs);
  if (fTypes.length === 0) {
    fTypes = allDocs;
  }
  winston.info(fDates);
  toFromDate = function(op, number, unit){
    var m;
    if (op === '<') {
      op = '>';
    } else {
      op = '<';
    }
    number = parseInt(number);
    m = moment().subtract(number, unit).toISOString();
    return "kMDItemFSContentChangeDate" + op + "$time.iso(" + m + ")";
  };
  getTimeReference = function(txt){
    var op, num, unit;
    op = txt.charAt(0);
    txt = txt.slice(1);
    num = 7;
    unit = 'days';
    winston.info('Getting time reference');
    winston.info(txt);
    if (_.endsWith(txt, 'd')) {
      num = txt.substring(0, txt.length - 1);
      unit = 'days';
      return toFromDate(op, num, unit);
    }
    if (_.endsWith(txt, 'y')) {
      num = txt.substring(0, txt.length - 1);
      unit = 'years';
      return toFromDate(op, num, unit);
    }
    if (_.endsWith(txt, 'm')) {
      num = txt.substring(0, txt.length - 1);
      unit = 'months';
      return toFromDate(op, num, unit);
    }
    if (_.endsWith(txt, 'h')) {
      num = txt.substring(0, txt.length - 1);
      unit = 'hours';
      return toFromDate(op, num, unit);
    }
    return undefined;
  };
  fire = _.any(fWords.concat(fName), function(it){
    return it.length > 4;
  }) || _.any(categorized, function(it){
    return it.type === "force";
  });
  qContents = (function(){
    var i$, ref$, len$, results$ = [];
    for (i$ = 0, len$ = (ref$ = fWords).length; i$ < len$; ++i$) {
      txt = ref$[i$];
      results$.push("(kMDItemTextContent=\"" + txt.slice(1) + "\"wc)");
    }
    return results$;
  }()).join(' && ');
  winston.info(qContents);
  qTypes = join$.call((function(){
    var i$, ref$, len$, results$ = [];
    for (i$ = 0, len$ = (ref$ = fTypes).length; i$ < len$; ++i$) {
      txt = ref$[i$];
      results$.push("kMDItemFSName=\"*." + txt.slice(1) + "\"wc");
    }
    return results$;
  }()).concat(["kMDItemKind=folder"]), ' || ');
  winston.info(qTypes);
  qName = (function(){
    var i$, ref$, len$, results$ = [];
    for (i$ = 0, len$ = (ref$ = fName).length; i$ < len$; ++i$) {
      txt = ref$[i$];
      results$.push("kMDItemFSName=\"*" + txt + "*\"wc");
    }
    return results$;
  }()).join(' || ');
  winston.info(qName);
  qDates = (function(){
    var i$, ref$, len$, results$ = [];
    for (i$ = 0, len$ = (ref$ = fDates).length; i$ < len$; ++i$) {
      txt = ref$[i$];
      results$.push(getTimeReference(txt));
    }
    return results$;
  }()).join(' && ');
  winston.info(qDates);
  query = _.filter([qContents, qTypes, qName, qDates], function(it){
    return it !== "";
  });
  query = (function(){
    var i$, ref$, len$, results$ = [];
    for (i$ = 0, len$ = (ref$ = query).length; i$ < len$; ++i$) {
      q = ref$[i$];
      results$.push("(" + q + ")");
    }
    return results$;
  }()).join(' && ');
  files = [];
  pquery = "'" + query + "'";
  shelljs.exec("echo " + pquery + " | pbcopy", {
    async: true,
    silent: true
  }, function(){});
  if (fire) {
    query = "mdfind " + pquery + " -onlyin ~";
    winston.info("Executing query " + query);
    child = shelljs.exec(query, {
      async: true,
      silent: true
    });
    child.stdout.on("data", function(output){
      var show;
      winston.info(output);
      files = _.lines(output);
      show = files.map(function(it){
        var type, item;
        type = path.extname(it).slice(1);
        item = {
          title: path.basename(it),
          subtitle: it,
          arg: it,
          valid: true
        };
        item.icon = {
          '@': {
            type: 'fileicon'
          },
          '#': it + ""
        };
        return new alfredo.Item(item);
      });
      return alfredo.feedback(show);
    });
  } else {
    alfredo.feedback(new alfredo.Item({
      title: "Try a longer term to search for",
      valid: false
    }));
  }
}).call(this);
