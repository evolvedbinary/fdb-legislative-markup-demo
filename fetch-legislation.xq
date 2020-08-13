xquery version "3.1";

(:~
 : Fetches UK Public General Acts from legislation.gov.uk.
 :
 : Acts are retrieved in  Akoma Ntoso (Legislative Markup Format),
 : and stored into the /db/ukpga database collection.
 :
 : @author Adam Retter <adam@evolvedbinary.com>
 :)

import module namespace http = "http://expath.org/ns/http-client";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace leg = "http://www.legislation.gov.uk/namespaces/legislation";
declare namespace ukm = "http://www.legislation.gov.uk/namespaces/metadata";

declare variable $local:ukpga-base-uri := "https://www.legislation.gov.uk/ukpga";

(:~
 : Performs a HTTP GET on a URI.
 :
 : Raises an error if the response is not HTTP 200 OK,
 : otherwise returns the response.
 :)
declare function local:fetch($uri as xs:string) {
    let $result := http:send-request(
        <http:request method="get" href="{$uri}"/>
    )
    return
        if ($result[1]/@status ne "200")
        then
            fn:error(xs:QName("local:bad-fetch-1"), $result[1], $uri)
        else
            $result[2]
};

(:~
 : Get's a page of the ATOM feed for a year of UK Public General Acts
 : from legislation.gov.uk.
 :
 : Fetches from a URI like https://www.legislation.gov.uk/ukpga/{$year}/data.feed?page={$page} 
 :)
declare function local:get-ukpga-feed($year as xs:integer, $page as xs:integer) as document-node(element(atom:feed)) {
    let $page-feed-uri := $local:ukpga-base-uri || "/" || $year || "/data.feed" || "?page=" || $page
    return
        local:fetch($page-feed-uri)
};

(:~
 : Get's all pages of the ATOM feed for a year of UK Public General Acts
 : from legislation.gov.uk.
 :
 : Calls local:get-ukpga-feed#2 once for each available page
 :)
declare function local:get-ukpga-feeds($year as xs:integer) as document-node(element(atom:feed))+ {
    let $first-page := local:get-ukpga-feed($year, 1)
    let $num-remaining-pages := ($first-page//leg:morePages/text(), 0)[1] cast as xs:integer
    let $remaining-pages := (2 to $num-remaining-pages) ! local:get-ukpga-feed($year, .)
    return
        ($first-page, $remaining-pages)
};

(:~
 : Returns the base name of a URI.
 :
 : This is done by dropping the path
 : part after the last '/'.
 :)
declare function local:base-name($uri) {
    replace($uri, "(.*)/.*", "$1")
};

(:~
 : Returns a resource name from a URI.
 :
 : This is done by dropping everything before
 : the last path part.
 :)
declare function local:name($uri) {
    replace($uri, ".*/([^/]*)", "$1")
};

(:~
 : Creates a database collection if it does not
 : yet exist.
 :)
declare function local:setup-collection($collection-uri) {
    if (not(xmldb:collection-available($collection-uri)))
    then
        xmldb:create-collection(local:base-name($collection-uri), local:name($collection-uri))
    else
        $collection-uri
};



let $db-collection-uri := local:setup-collection("/db/ukpga")

let $years := (1900 to 2020)
for $year in $years
return
    let $_ := util:log("info", ("Processing Year: " || $year))
    let $ukgpa-atom-feeds := local:get-ukpga-feeds($year)
    let $ukpga-akn-uris := $ukgpa-atom-feeds//atom:entry/atom:link[@rel eq "alternate"][@type eq "application/akn+xml"]/@href/string()
    for $ukpga-akn-uri in $ukpga-akn-uris
    return 
        let $_ := util:log("info", ("Fetching: " || $ukpga-akn-uri))
        let $ukgpa-akn := 
            try {
                local:fetch($ukpga-akn-uri)
            } catch local:bad-fetch-1 {
                <failed uri="{$ukpga-akn-uri}"/>
            }
        return
            if ($ukgpa-akn instance of element(failed))
            then
                $ukgpa-akn
            else
                let $doc-name := util:uuid() || ".akn.xml"
                let $doc-uri := xmldb:store($db-collection-uri, $doc-name, $ukgpa-akn, "application/xml")
                return
                    <stored uri="{$doc-uri}"/>
    