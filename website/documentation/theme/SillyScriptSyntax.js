(function() {
    "use strict";

    var e = function(e) {
        return {
            name: "SillyScript",
            aliases: ["silly"],
            keywords: {
                keyword: "alias as block break case cast catch const continue decor def default delete do dynamic dyn else enum extends extern for from function if import in inline is loop macro modify new override pass priv pub replace rename return runonce self static super switch template this throw to trace try type untyped using var while wrapper Int int Float float String str Bool bool Dynamic Void void Array expr typeDef field ",
                built_in: "trace self",
                literal: "true false null _",
            },
            contains: [{
                    className: "string",
                    begin: "'",
                    end: "'",
                    contains: [
                        e.BACKSLASH_ESCAPE,
                        {
                            className: "subst",
                            begin: "\\$\\{",
                            end: "\\}",
                        },
                        {
                            className: "subst",
                            begin: "\\$",
                            end: /\w(?=\W)/
                        },
                    ],
                },
                {
                    className: "string",
                    begin: "\"",
                    end: "\"",
                    contains: [
                        e.BACKSLASH_ESCAPE,
                    ],
                },
                e.HASH_COMMENT_MODE,
                {
                    scope: 'comment',
                    begin: '###',
                    end: '###'
                },
                {
                    className: 'number',
                    scope: 'number',
                    begin: e.C_NUMBER_RE + "\\.\\.\\." + e.C_NUMBER_RE,
                    relevance: 0
                },
                {
                    className: 'attribute',
                    begin: "\\$\\w+",
                    relevance: 0
                },
                {
                    className: 'keyword',
                    begin: "`",
                    relevance: 0
                },
                {
                    className: "function",
                    begin: /\w+\!?(?=[\($])/,
                    relevance: 1
                },
                e.C_NUMBER_MODE,
                {
                    className: "attribute",
                    begin: /\@"/,
                    end: /"/,
                },
                {
                    className: "attribute",
                    begin: /\@/,
                    end: /\w(?=[\($\n])/,
                },
                //{ className: "type", begin: ":[ \t]*\w+", relevance: 0 },
                //{ className: "type", begin: ":[ \t]*", end: "\\W", excludeBegin: !0, excludeEnd: !0 },
                //{ className: "type", begin: "new *", end: "\\W", excludeBegin: !0, excludeEnd: !0 },
                {
                    className: "class",
                    beginKeywords: "enum",
                    end: ":",
                    contains: [e.TITLE_MODE]
                },
                {
                    className: "class",
                    beginKeywords: "abstract",
                    end: "[:$]",
                    contains: [{
                            className: "type",
                            begin: "\\(",
                            end: "\\)",
                            excludeBegin: !0,
                            excludeEnd: !0
                        },
                        {
                            className: "type",
                            begin: "from +",
                            end: "\\W",
                            excludeBegin: !0,
                            excludeEnd: !0
                        },
                        {
                            className: "type",
                            begin: "to +",
                            end: "\\W",
                            excludeBegin: !0,
                            excludeEnd: !0
                        },
                        e.TITLE_MODE,
                    ],
                    keywords: {
                        keyword: "abstract from to"
                    },
                },
                {
                    className: "class",
                    begin: "\\b(class|interface|modify) +",
                    end: "[:$]",
                    excludeEnd: !0,
                    keywords: "class interface modify",
                    contains: [{
                            className: "keyword",
                            begin: "\\b(extends|implements) +",
                            keywords: "extends implements",
                            contains: [{
                                className: "type",
                                begin: e.IDENT_RE,
                                relevance: 0,
                            }, ],
                        },
                        e.TITLE_MODE,
                    ],
                },
                {
                    className: "function",
                    beginKeywords: "function",
                    end: "\\(",
                    excludeEnd: !0,
                    illegal: "\\S",
                    contains: [e.TITLE_MODE],
                },
            ],
            illegal: /<\//,
        };
    };

    hljs.registerLanguage("sillyscript", e);
})();