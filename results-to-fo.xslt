<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:param name="keywords" required="no"/>
    <xsl:param name="modified-after" required="no"/>
    
    <xsl:param name="logoUri" required="no" select="'http://static.adamretter.org.uk/eb-logo.png'"/>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="results">
        <fo:root font-size="12pt">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="A4" page-width="297mm" page-height="210mm" margin-top="1cm" margin-bottom="1cm" margin-left="1cm" margin-right="1cm">
                    <fo:region-body margin-top="5.2cm" margin-left="1cm" margin-bottom="1cm" margin-right="1cm"/>
                    <fo:region-before extent="4.2cm"/>
                    <fo:region-after extent="1cm"/>
                    <fo:region-start extent="1cm"/>
                    <fo:region-end extent="1cm"/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            <fo:page-sequence master-reference="A4">
                <fo:static-content flow-name="xsl-region-before">
                    <fo:block text-align="center" vertical-align="top">
                        <fo:block background-repeat="repeat-x">
                            <fo:external-graphic src="url({$logoUri})" content-height="scale-to-fit" content-width="scale-to-fit" scaling="uniform" height="40mm"/>
                            <!-- fo:external-graphic src="url({$logoUri})" content-height="scale-to-fit" content-width="scale-to-fit" scaling="uniform" height="18mm"/ -->
                        </fo:block>
                    </fo:block>
                    <fo:block text-align="left" margin-top="0.2cm" font-size="12pt" border-bottom-width="thin" border-bottom-style="solid" border-bottom-color="black">
                        Search Results for keywords: "<xsl:value-of select="$keywords"/>", and modified after: <xsl:value-of select="$modified-after"/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="xsl-region-after">
                    <fo:block font-family="verdana" font-size="8pt" color="grey" text-align="center">
                        Page <fo:page-number/> of <fo:page-number-citation ref-id="last-page"/>
                    </fo:block>
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body">
                    <xsl:apply-templates select="ukpga"/>
                    
                    <fo:block id="last-page"> </fo:block>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
        
    </xsl:template>
    
    <xsl:template match="ukpga">
        <fo:block margin-top="0.25cm">
            <fo:block font-size="10pt" color="blue" font-weight="bold">
                <xsl:value-of select="shortTitle"/>
            </fo:block>
            <fo:block>
                <fo:basic-link external-destination="{@id}"><xsl:value-of select="@id"/></fo:basic-link>
            </fo:block>
            <fo:block font-size="9pt" font-family="verdana">
                <xsl:value-of select="longTitle"/>
            </fo:block>
            <fo:block>
                <fo:inline font-weight="bold">Score:</fo:inline> <fo:inline font-weight="italic"><xsl:value-of select="format-number(xs:float(@search-score) * 100, '###0.00')"/> %</fo:inline>
            </fo:block>
        </fo:block>
    </xsl:template>
    
</xsl:stylesheet>