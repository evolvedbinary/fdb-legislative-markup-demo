xquery version "3.1";

(:~
 : Examples of simple structural and full-text queries
 : against UK Public General Acts.
 :
 : Note that each example builds on the previous example.
 :
 : @author Adam Retter <adam@evolvedbinary.com>
 :)

import module namespace ft = "http://exist-db.org/xquery/lucene";

declare namespace akn = "http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace ukm = "http://www.legislation.gov.uk/namespaces/metadata";

(:~
 : 1. Count of all UK Public General Acts.
 :
 : Demonstrates a very simple XPath
 : for retrieving the documents
 : and counting them.
 :)
(:
count(
    collection("/db/ukpga")/akn:akomaNtoso
)
:)


(:~
 : 2. Years covered by UK Public General Acts
 :
 : Demonstrates:
 :   * Data typing by converting the Year from text to an integer
 :   * Filtering a set of values to a set of unique (distinct) values
 :   * Sorting the results by the (integer) Year
 :   * Finding the range (min/max) of the (integer) Year
 :   * Mapping values to output (using the Simple Map Operator `!`)
 :)
 (:
let $years := sort(distinct-values(
    collection("/db/ukpga")//ukm:PrimaryMetadata/ukm:Year/xs:integer(@Value)
))
return
    <ukpgas from="{min($years)}" to="{max($years)}">
    {
        $years ! <year>{.}</year>
    }
    </ukpgas>
:)


(:~
 : 3. Titles of UK Public General Acts grouped by year
 :
 : Demonstrates:
 :   * Grouping results by the (integer) Year.
 :   * Explicitly ordering the results in descending order.
 :   * Conditionally generating output if the source data is as desired.
 :)
 (:
<ukpgas>
{
    for $act in collection("/db/ukpga")/akn:akomaNtoso/akn:act
    let $year := $act/akn:meta/akn:proprietary/ukm:PrimaryMetadata/ukm:Year/xs:integer(@Value)
    group by $year
    order by $year descending
    return
        <year value="{$year}" acts="{count($act)}">
        {
            for $individual-act in $act
            let $preface := $individual-act//akn:preface
            let $short-title := string-join($preface//akn:shortTitle//text(), "")
            let $long-title := string-join($preface/akn:longTitle//text(), "")
            return
                <ukpga id="{$individual-act//dc:identifier}" docNumber="{$preface//akn:docNumber}">
                {
                    if (string-length($short-title) gt 0) then <shortTitle>{$short-title}</shortTitle> else(),
                    if (string-length($long-title) gt 0) then <longTitle>{$long-title}</longTitle> else()
                }
                </ukpga>
        }
        </year>
}
</ukpgas>
:)


(:~
 : 4. Full-text search of a UK Public General Act
 : within the preface of the document (includes
 : things like short and long titles)
 :
 : Demonstrates:
 :   * Full-text search via Lucene using the ft:query function
 :   * Ordering the results by their full-text search score.
 :   * Generating output annotated with metadata about their search context.
 :)
(:
let $keywords := "building"

    let $search-results := 
        for $act in collection("/db/ukpga")//akn:akomaNtoso/akn:act[ft:query(akn:preface, $keywords)]
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
:)


(:~
 : 5. Full-text combined with range search of a UK Public General Act.
 :  
 :    Full-text is searched within the preface and body of the act
 :    whilst the range searches for a modified after date.
 :
 : Demonstrates:
 :   * Combing a range search with Full-text search
 :)
let $keywords := "school"
let $modified-after := xs:date("2020-01-01")

    let $search-results := 
        for $act in collection("/db/ukpga")//akn:akomaNtoso/akn:act[ft:query(akn:preface|akn:body, $keywords)][akn:meta/akn:proprietary/dc:modified gt $modified-after]
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
