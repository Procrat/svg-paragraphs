<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:math="http://exslt.org/math"
  exclude-result-prefixes="math">

  <xsl:output method="xml" indent="yes"
    doctype-system="http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd"
    doctype-public="-//W3C//DTD SVG 1.0//EN" />

  <xsl:template match="/document">
    <xsl:variable name="width" select="math:max(.//@line-width)" />
    <xsl:variable name="font-size" select="@font-size" />
    <xsl:variable name="height" select="$font-size * (count(.//line) + count(.//paragraph) - .5)"/>

    <svg width="{$width}" height="{$height}" xmlns="http://www.w3.org/2000/svg">
      <rect width="{$width}" height="{$height}" style="fill:none;stroke-width:1;stroke:rgb(0,0,0);" />

      <xsl:for-each select="paragraph">
        <g font-family="monospace" style="font-size:{$font-size}">
          <xsl:for-each select="line">
            <text>
              <xsl:call-template name="construct-line">
                <xsl:with-param name="font-size" select="$font-size" />
              </xsl:call-template>
            </text>
          </xsl:for-each>
        </g>
      </xsl:for-each>

    </svg>
  </xsl:template>

  <xsl:template name="construct-line">
    <xsl:param name="font-size" />

    <xsl:variable name="y" select="(count(./preceding::line) + count(./preceding::paragraph) + 1) * $font-size" />

    <xsl:for-each select="box">
      <xsl:variable name="boxes-width" select="sum(./preceding-sibling::node()/@width)" />
      <xsl:variable name="glue-adjustment"
        select="(../@ratio &lt; 0) * sum(./preceding-sibling::glue/@shrinkability) +
                (../@ratio &gt; 0) * sum(./preceding-sibling::glue/@stretchability)" />
      <xsl:variable name="x" select="$boxes-width + ../@ratio * $glue-adjustment" />

      <tspan x="{$x}" y="{$y}" textLength="{@width}">
        <xsl:copy-of select="text()" />
      </tspan>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
