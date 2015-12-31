<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:math="http://exslt.org/math"
  exclude-result-prefixes="exslt math">

  <xsl:output method="xml" indent="yes" />

  <xsl:template match="/document">
    <xsl:copy>
      <xsl:copy-of select="@*" />

      <xsl:for-each select="paragraph">
        <xsl:copy>
          <xsl:copy-of select="@*" />

          <!-- Find cascading line-width attribute -->
          <xsl:variable name="line-width">
            <xsl:value-of select="@line-width" />
            <xsl:if test="not(@line-width)"><xsl:value-of select="../@line-width" /></xsl:if>
          </xsl:variable>

          <content>
            <xsl:copy-of select="*" />
          </content>

          <xsl:variable name="initial-branch">
            <branch start="0" end="0" cost="0">0</branch>
          </xsl:variable>

          <xsl:variable name="branches-rtf">
            <xsl:call-template name="recursively-construct-branches">
              <xsl:with-param name="line-width" select="$line-width" />
              <xsl:with-param name="branches" select="exslt:node-set($initial-branch)/*" />
              <xsl:with-param name="current-node-pos" select="1" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="branches" select="exslt:node-set($branches-rtf)/*" />

          <branches>
            <xsl:for-each select="$branches">
              <xsl:copy><xsl:copy-of select="@*" /></xsl:copy>
            </xsl:for-each>
          </branches>

        </xsl:copy>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="recursively-construct-branches">
    <xsl:param name="line-width" />
    <xsl:param name="branches" />
    <xsl:param name="current-node-pos" />

    <xsl:variable name="paragraph" select="*" />

    <xsl:choose>
      <xsl:when test="$current-node-pos &lt;= count(*) + 1">
        <xsl:choose>
          <xsl:when test="name(*[$current-node-pos]) = 'glue'">

            <xsl:variable name="possible-branches-rtf">
              <xsl:call-template name="calculate-possible-branches">
                <xsl:with-param name="line-width" select="$line-width" />
                <xsl:with-param name="paragraph" select="$paragraph" />
                <xsl:with-param name="current-node-pos" select="$current-node-pos" />
                <xsl:with-param name="branches" select="$branches" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="possible-branches" select="exslt:node-set($possible-branches-rtf)/*" />

            <xsl:variable name="n-bad-branches" select="count($possible-branches[@ratio &lt; -1])" />

            <xsl:copy-of select="$branches[position() &lt;= $n-bad-branches and @end &gt; 0]" />

            <xsl:variable name="minimal-cost-branch"
              select="math:lowest($possible-branches[@ratio &gt;= -1])[1]" />

            <xsl:variable name="next-branches-rtf">
              <xsl:copy-of select="$branches[position() &gt; $n-bad-branches]" />
              <xsl:copy-of select="$minimal-cost-branch" />
            </xsl:variable>
            <xsl:variable name="next-branches" select="exslt:node-set($next-branches-rtf)/*" />

            <xsl:call-template name="recursively-construct-branches">
              <xsl:with-param name="line-width" select="$line-width" />
              <xsl:with-param name="branches" select="$next-branches" />
              <xsl:with-param name="current-node-pos" select="$current-node-pos + 1" />
            </xsl:call-template>

          </xsl:when>

          <xsl:otherwise>
            <xsl:call-template name="recursively-construct-branches">
              <xsl:with-param name="line-width" select="$line-width" />
              <xsl:with-param name="branches" select="$branches" />
              <xsl:with-param name="current-node-pos" select="$current-node-pos + 1" />
            </xsl:call-template>
          </xsl:otherwise>

        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <xsl:copy-of select="$branches" />

        <xsl:variable name="possible-branches-rtf">
          <xsl:call-template name="calculate-possible-branches">
            <xsl:with-param name="line-width" select="$line-width" />
            <xsl:with-param name="paragraph" select="$paragraph" />
            <xsl:with-param name="current-node-pos" select="$current-node-pos" />
            <xsl:with-param name="branches" select="$branches" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="possible-branches" select="exslt:node-set($possible-branches-rtf)/*" />

        <xsl:copy-of select="math:lowest($possible-branches[@ratio &gt;= -1])[1]" />
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <xsl:template name="calculate-possible-branches">
    <xsl:param name="line-width" />
    <xsl:param name="paragraph" />
    <xsl:param name="current-node-pos" />
    <xsl:param name="branches" />

    <xsl:variable name="current-node" select="$paragraph[$current-node-pos]" />

    <xsl:for-each select="$branches">
      <xsl:variable name="start">
        <xsl:call-template name="find-start-without-discardables">
          <xsl:with-param name="prev-end" select="@end" />
          <xsl:with-param name="paragraph" select="$paragraph" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="end" select="$current-node-pos" />
      <xsl:variable name="line" select="$paragraph[$start &lt; position() and position() &lt; $end]" />

      <xsl:variable name="ratio">
        <xsl:call-template name="calculate-ratio">
          <xsl:with-param name="line-width" select="$line-width" />
          <xsl:with-param name="line" select="$line" />
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="glue-cost">
        <xsl:call-template name="calculate-cost">
          <xsl:with-param name="ratio" select="$ratio" />
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="penalty-cost">
        <xsl:call-template name="parse-penalty">
          <xsl:with-param name="penalty" select="$current-node/preceding-sibling::*[1]/@penalty" />
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="cost" select="$glue-cost + $penalty-cost" />

      <xsl:variable name="prev-cost" select="number(text())" />

      <xsl:if test="$cost = number($cost)">
        <branch ratio="{$ratio}" previous="{@end}" cost="{$cost}" start="{$start}" end="{$end}">
          <xsl:value-of select="$prev-cost + $cost" />
        </branch>
      </xsl:if>

    </xsl:for-each>
  </xsl:template>

  <!-- Find start of line, discarding glue and penalties at start of line, except at start of paragraph -->
  <xsl:template name="find-start-without-discardables">
    <xsl:param name="prev-end" />
    <xsl:param name="paragraph" />

    <xsl:choose>
      <xsl:when test="$prev-end = 0">
        <xsl:value-of select="0" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="count($paragraph[position() &gt; $prev-end][name() = 'box'][1]/preceding-sibling::*)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="calculate-ratio">
    <xsl:param name="line-width" />
    <xsl:param name="line" />

    <xsl:variable name="stretchabilities" select="sum($line//@stretchability)" />
    <xsl:variable name="nominal-width" select="sum($line//@width)" />
    <xsl:variable name="shrinkabilities" select="sum($line//@shrinkabilities)" />

    <xsl:choose>
      <xsl:when test="$nominal-width = $line-width">
        <xsl:value-of select="0" />
      </xsl:when>
      <xsl:when test="$nominal-width &lt; $line-width">
        <xsl:value-of select="($line-width - $nominal-width) div $stretchabilities" />
      </xsl:when>
      <xsl:when test="$nominal-width &gt; $line-width">
        <xsl:value-of select="($line-width - $nominal-width) div $shrinkabilities" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="calculate-cost">
    <xsl:param name="ratio" />

    <xsl:choose>
      <xsl:when test="$ratio &lt; -1">
        <xsl:value-of select="1 div 0" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="abs-ratio" select="($ratio &lt; 0)*(-$ratio) + ($ratio &gt; 0)*$ratio" />
        <xsl:value-of select="floor(100 * ($abs-ratio * $abs-ratio * $abs-ratio) + 0.5)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="parse-penalty">
    <xsl:param name="penalty" />

    <xsl:choose>
      <xsl:when test="$penalty = 'INF'">
        <xsl:value-of select="1 div 0" />
      </xsl:when>
      <xsl:when test="$penalty = '-INF'">
        <xsl:value-of select="-1 div 0" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="sum($penalty)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
