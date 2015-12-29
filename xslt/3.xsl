<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:math="http://exslt.org/math"
  exclude-result-prefixes="exslt math">

  <xsl:output method="xml" indent="yes" />

  <xsl:template match="/document">
    <xsl:copy>
      <xsl:copy-of select="@*" />

      <xsl:for-each select="paragraph">
        <xsl:copy-of select="@*" />

        <xsl:copy>
          <xsl:variable name="end" select="math:max(branches/branch/@end)" />
          <!-- <xsl:message> -->
            <!-- End: <xsl:value-of select="$end" /> -->
          <!-- </xsl:message> -->

          <xsl:call-template name="backtrack-dag">
            <xsl:with-param name="end" select="$end" />
          </xsl:call-template>
        </xsl:copy>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="backtrack-dag">
    <xsl:param name="end" />
    <xsl:param name="lines" select="/.." />
    
    <xsl:choose>
      <xsl:when test="$end &gt; 0">
        <xsl:variable name="branch" select="branches/branch[@end = $end]" />
        
        <!-- <xsl:message> -->
          <!-- Branch: <xsl:copy-of select="$branch" /> -->
        <!-- </xsl:message> -->

        <xsl:variable name="new-lines-raw">
          <line ratio="{$branch/@ratio}">
            <xsl:copy-of select="content/*[$branch/@start &lt; position() and position() &lt; $branch/@end]" />
          </line>
          <xsl:copy-of select="$lines" />
        </xsl:variable>
        <xsl:variable name="new-lines" select="exslt:node-set($new-lines-raw)" />
        
        <!-- <xsl:message> -->
          <!-- New lines: <xsl:copy-of select="$new-lines" /> -->
        <!-- </xsl:message> -->

        <xsl:call-template name="backtrack-dag">
          <xsl:with-param name="end" select="$branch/@start" />
          <xsl:with-param name="lines" select="$new-lines" />
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:copy-of select="$lines" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
