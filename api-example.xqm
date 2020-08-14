xquery version "3.1";

(:~
 : Examples of creating a RESTXQ API for
 : simple structural and full-text queries
 : against UK Public General Acts.
 :
 : Note that each example builds on the previous example.
 :
 : @author Adam Retter <adam@evolvedbinary.com>
 :)

module namespace lm = "http://evolvedbinary.com/ns/demo/lm";

import module namespace ft = "http://exist-db.org/xquery/lucene";
import module namespace transform = "http://exist-db.org/xquery/transform";

declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace ukm = "http://www.legislation.gov.uk/namespaces/metadata";


(:~
 : 6. Writing a user defined function.
 :
 : This is just Example 5 from `simple-queries.xq`
 : adapted into a function that takes the `keywords`
 : and `modified-after` values as optional parameters.
 :
 : Full-text combined with range search of a UK Public General Act.
 :
 : Demonstrates:
 :   * Creating a custom function
 :   * Parameterizing the search criteria
 :   * Dealing with optional parameters (search criteria)
 :)
declare
    %private
function lm:search($keywords as xs:string?, $modified-after as xs:date?) as element(results) {
    let $search-results := 
        for $act in
            if (not(empty($keywords)) and not(empty($modified-after)))
            then
                collection("/db/ukpga")//akn:akomaNtoso/akn:act[ft:query(akn:preface|akn:body, $keywords)][akn:meta/akn:proprietary/dc:modified gt $modified-after]
            else if (not(empty($keywords)))
            then
                collection("/db/ukpga")//akn:akomaNtoso/akn:act[ft:query(akn:preface|akn:body, $keywords)]
            else if (not(empty($modified-after)))
            then
                collection("/db/ukpga")//akn:akomaNtoso/akn:act[akn:meta/akn:proprietary/dc:modified gt $modified-after]
            else
                collection("/db/ukpga")//akn:akomaNtoso/akn:act
        let $preface := $act//akn:preface
        let $short-title := string-join($preface//akn:shortTitle//text(), "")
        let $long-title := string-join($preface/akn:longTitle//text(), "")
        let $search-score := ft:score($act)
        order by $search-score descending
        return
            <ukpga id="{$act//dc:identifier}" docNumber="{$preface//akn:docNumber}" search-score="{$search-score}">
            {
                if (string-length($short-title) gt 0) then <shortTitle>{$short-title}</shortTitle> else(),
                if (string-length($long-title) gt 0) then <longTitle>{$long-title}</longTitle> else()
            }
            </ukpga>
    return 
        <results count="{count($search-results)}">
        {
            $search-results
        }
        </results>
};


(:~
 : 7. A RESTXQ API resource function that
 : takes two http query parameters
 : and delivers the results as XML.
 :
 : The URI to call will have the form:
 :   http://localhost:4059/exist/restxq/lm/search?keywords=building&modified-after=2020-01-01
 :
 : Demonstrates the use of RESTXQ function annotations
 : to deliver an HTTP API.
 :)
declare
    %rest:GET
    %rest:path("/lm/search")
    %rest:query-param("keywords", "{$keywords}")
    %rest:query-param("modified-after", "{$modified-after}")
    %rest:produces("application/xml")
function lm:search-xml($keywords, $modified-after) {

    (: just call our search function defined at the top! :)
    lm:search($keywords, $modified-after)
};


(:~
 : 8. A RESTXQ API resource function that
 : takes two http query parameters
 : and delivers the results as JSON.
 :
 : The URI to call will have the form:
 :   http://localhost:4059/exist/restxq/lm/search?keywords=building&modified-after=2020-01-01
 : However, the HTTP Accept header in the request must contain `application/json`
 : e.g. If you use curl:
 :  curl -H 'Accept: application/json' http://admin@localhost:4059/exist/restxq/lm/search?keywords=building&modified-after=2020-01-01
 :
 : Demonstrates the use of the `%output:method` annotation
 : from the W3C XSLT and XQuery Serialization specification
 : to transparently produce JSON.
 :)
declare
    %rest:GET
    %rest:path("/lm/search")
    %rest:query-param("keywords", "{$keywords}")
    %rest:query-param("modified-after", "{$modified-after}")
    %rest:produces("application/json")
    %output:method("json")
function lm:search-json($keywords, $modified-after) {

    (: just call our search function defined at the top! :)
    lm:search($keywords, $modified-after)
};

(:~
 : 9. A RESTXQ API resource function that
 : takes two http query parameters
 : and delivers the results as HTML.
 :
 : The URI to call will have the form:
 :   http://localhost:4059/exist/restxq/lm/web/search?keywords=building&modified-after=2020-01-01
 :
 : Demonstrates:
 :   * Use of the `%output:method` annotation from
 :     the W3C XSLT and XQuery Serialization specification
 :     to transparently produce HTML.
 :   * Transforming XML into XHTML using XSLT.
 :)
declare
    %rest:GET
    %rest:path("/lm/web/search")
    %rest:query-param("keywords", "{$keywords}")
    %rest:query-param("modified-after", "{$modified-after}")
    %rest:produces("text/html")
    %output:method("html5")
function lm:search-html($keywords, $modified-after) {

    let $search-results := lm:search($keywords, $modified-after)
    let $xslt := doc("/db/results-to-xhtml.xslt")
    return
        transform:transform($search-results, $xslt,
            <parameters>
                <param name="keywords" value="{$keywords}"/>
                <param name="modified-after" value="{$modified-after}"/>
            </parameters>
        )
};
