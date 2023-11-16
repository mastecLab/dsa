ace.define('ace/mode/dgscript', function (require, exports, module) {

  var oop = require("ace/lib/oop");
  var TextMode = require("ace/mode/text").Mode;
  var Tokenizer = require("ace/tokenizer").Tokenizer;
  var DGHighlightRules = require("ace/mode/dgscript_highlight_rules").HighlightRules;
  var CstyleBehaviour = require("./behaviour/cstyle").CstyleBehaviour;
  var CStyleFoldMode = require("./folding/cstyle").FoldMode;
  var MatchingBraceOutdent = require("./matching_brace_outdent").MatchingBraceOutdent;

  var Mode = function () {
    this.$tokenizer = new Tokenizer(new DGHighlightRules().getRules());
    this.$outdent = new MatchingBraceOutdent();
    this.$behaviour = new CstyleBehaviour();
    this.foldingRules = new CStyleFoldMode();
    this.$highlightRules = new DGHighlightRules();
    this.HighlightRules = DGHighlightRules;
  };

  oop.inherits(Mode, TextMode);

  (function () {
    this.lineCommentStart = "//";
    this.blockComment = {start: "/*", end: "*/"};

    this.getNextLineIndent = function (state, line, tab) {
      var indent = this.$getIndent(line);

      var tokenizedLine = this.getTokenizer().getLineTokens(line, state);
      var tokens = tokenizedLine.tokens;
      var endState = tokenizedLine.state;

      if (tokens.length && tokens[tokens.length - 1].type == "comment") {
        return indent;
      }

      if (state == "start" || state == "no_regex") {
        var matcha = line.match(/^.*(?:\bcase\b.*\:|[\{\(\[])\s*$/);
        if (matcha) {
          indent += tab;
        }
      } else if (state == "doc-start") {
        if (endState == "start" || endState == "no_regex") {
          return "";
        }
        var match = line.match(/^\s*(\/?)\*/);
        if (match) {
          if (match[1]) {
            indent += " ";
          }
          indent += "* ";
        }
      }

      return indent;
    };

    this.checkOutdent = function (state, line, input) {
      return this.$outdent.checkOutdent(line, input);
    };

    this.autoOutdent = function (state, doc, row) {
      this.$outdent.autoOutdent(doc, row);
    };
  }).call(Mode.prototype);

  this.$id = "ace/mode/dgscript";

  exports.Mode = Mode;
});

ace.define('ace/mode/dgscript_highlight_rules', function (require, exports, module) {
  var oop = require("ace/lib/oop");
  var JavaScriptHighlightRules = require("ace/mode/javascript_highlight_rules").JavaScriptHighlightRules;

  var DGHighlightRules = function () {
    this.$rules = new JavaScriptHighlightRules().getRules();
  };

  oop.inherits(DGHighlightRules, JavaScriptHighlightRules);

  exports.HighlightRules = DGHighlightRules;
});