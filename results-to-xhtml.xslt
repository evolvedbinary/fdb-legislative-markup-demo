<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:param name="keywords" required="no"/>
    <xsl:param name="modified-after" required="no"/>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="results">
        <html>
            <head>
                <title>Search Results</title>
            </head>
            <body>
                <h1>Search Results</h1>
                <div>
                    <form method="get">
                        <div>
                            Keywords: <input type="text" name="keywords" id="keywords" value="{$keywords}"/>
                        </div>
                        <div>
                            Modified After: <input type="text" name="modified-after" id="modified-after" value="{$modified-after}"/>
                        </div>
                        <div>
                            <input type="submit" value="Search"/>
                        </div>
                    </form>
                </div>
                <h2>Found: <xsl:value-of select="@count"/> matches</h2>
                <hr/>
                <div>
                    <xsl:apply-templates/>
                </div>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="ukpga">
        <div>
            <h5><a href="{@id}"><xsl:value-of select="shortTitle"/></a></h5>
            <div><xsl:value-of select="longTitle"/></div>
            <div><b>Score:</b> <i><xsl:value-of select="format-number(xs:float(@search-score) * 100, '###0.00')"/> %</i></div>
        </div>
    </xsl:template>
    
    
    <!-- identity transform (as default) -->
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>