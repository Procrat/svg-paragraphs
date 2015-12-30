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

          <branches>
            <xsl:variable name="initial-branch">
              <branch start="0" end="0" cost="0" />
            </xsl:variable>

            <xsl:call-template name="recursively-construct-branches">
              <xsl:with-param name="line-width" select="$line-width" />
              <xsl:with-param name="branches" select="exslt:node-set($initial-branch)/*" />
              <xsl:with-param name="current-node-pos" select="1" />
            </xsl:call-template>
          </branches>

        </xsl:copy>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="recursively-construct-branches">
    <xsl:param name="line-width" />
    <xsl:param name="branches" />
    <xsl:param name="current-node-pos" />

    <xsl:choose>
      <xsl:when test="$current-node-pos &lt;= count(*)">
        <xsl:choose>
          <xsl:when test="*[$current-node-pos][name() = 'glue']">

            <!-- <xsl:message> -->
              <!--   Call: -->
              <!--     Curr-node: <xsl:value-of select="$current-node-pos" />, -->
              <!--     Branches: <xsl:copy-of select="$branches" />, -->
            <!-- </xsl:message> -->

            <xsl:variable name="paragraph" select="*" />

            <!-- <xsl:message> -->
              <!--   Paragraph: <xsl:copy-of select="$paragraph" /> -->
              <!-- </xsl:message> -->

            <xsl:variable name="possible-branches-raw">
              <xsl:for-each select="$branches">
                <xsl:variable name="start" select="@end" />
                <xsl:variable name="end" select="$current-node-pos" />

                <!-- <xsl:message> -->
                  <!-- Start: <xsl:value-of select="$start" /> -->
                  <!-- End: <xsl:value-of select="$end" /> -->
                  <!-- Paragraph: <xsl:copy-of select="$paragraph[$start &lt; position() and position() &lt;= $end]" /> -->
                <!-- </xsl:message> -->

                <xsl:variable name="ratio">
                  <xsl:call-template name="calculate-ratio">
                    <xsl:with-param name="line-width" select="$line-width" />
                    <xsl:with-param name="line" select="$paragraph[$start &lt; position() and position() &lt; $end]" />
                  </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="cost">
                  <xsl:if test="$ratio &gt;= -1">
                    <xsl:call-template name="calculate-cost">
                      <xsl:with-param name="ratio" select="$ratio" />
                    </xsl:call-template>
                  </xsl:if>
                </xsl:variable>

                <!-- <xsl:message> -->
                <!--   <branch ratio="{$ratio}" cost="{$cost}" start="{$start}" end="{$end}"> -->
                <!--     <xsl:value-of select="@cost + $cost" /> -->
                <!--   </branch> -->
                <!-- </xsl:message> -->

                <!-- <xsl:if test="$cost = number($cost)"> -->
                  <branch ratio="{$ratio}" cost="{@cost + $cost}" start="{$start}" end="{$end}">
                    <xsl:value-of select="@cost + $cost" />
                  </branch>
                <!-- </xsl:if> -->

              </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="possible-branches" select="exslt:node-set($possible-branches-raw)/*" />

            <!-- <xsl:message> -->
              <!-- Possible-branches: <xsl:copy-of select="$possible-branches" /> -->
            <!-- </xsl:message> -->

            <xsl:variable name="n-bad-branches" select="count($possible-branches[@ratio &lt; -1])" />

            <!-- <xsl:message> -->
              <!-- N bad branches: <xsl:value-of select="$n-bad-branches" /> -->
            <!-- </xsl:message> -->

            <xsl:for-each select="$branches[position() &lt;= $n-bad-branches]">
              <xsl:copy>
                <xsl:copy-of select="@*" />
              </xsl:copy>
            </xsl:for-each>

            <xsl:variable name="minimal-cost-branch">
              <xsl:copy-of select="math:lowest($possible-branches[@ratio &gt;= -1 and @cost = number(@cost)])" />
            </xsl:variable>

            <!-- <xsl:message> -->
              <!-- Minimal cost branch: <xsl:copy-of select="$minimal-cost-branch" /> -->
            <!-- </xsl:message> -->

            <xsl:variable name="next-branches-raw">
              <xsl:copy-of select="$branches[position() &gt; $n-bad-branches]" />
              <xsl:copy-of select="$minimal-cost-branch" />
            </xsl:variable>
            <xsl:variable name="next-branches" select="exslt:node-set($next-branches-raw)/*" />

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

          <!-- <xsl:when test="*[1][name() = 'penalty']"> -->
            <!-- </xsl:when> -->
          <!-- <xsl:when test="*[1][name() = 'box']"> -->
            <!-- </xsl:when> -->
        </xsl:choose>

      </xsl:when>

      <xsl:otherwise>
        <xsl:copy-of select="$branches" />
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <xsl:template name="calculate-ratio">
    <xsl:param name="line-width" />
    <xsl:param name="line" />

    <!-- <xsl:message> -->
      <!-- Calc ratio for line: -->
      <!-- <xsl:copy-of select="$line" /> -->
    <!-- </xsl:message> -->

    <xsl:variable name="stretchabilities" select="sum($line//@stretchability)" />
    <xsl:variable name="nominal-width" select="sum($line//@width)" />
    <xsl:variable name="shrinkabilities" select="sum($line//@shrinkabilities)" />

    <xsl:choose>
      <xsl:when test="$nominal-width = $line-width">
        <xsl:value-of select="0" />
      </xsl:when>
      <xsl:when test="$nominal-width &lt; $line-width">
        <!-- <xsl:choose> -->
          <!-- <xsl:when test="$stretchabilities &gt; 0"> -->
            <xsl:value-of select="($line-width - $nominal-width) div $stretchabilities" />
            <!-- </xsl:when> -->
          <!-- <xsl:otherwise> -->
            <!-- <xsl:value-of select="'UNDEFINED'" /> -->
            <!-- </xsl:otherwise> -->
          <!-- </xsl:choose> -->
      </xsl:when>
      <xsl:when test="$nominal-width &gt; $line-width">
        <!-- <xsl:choose> -->
          <!-- <xsl:when test="$shrinkabilities &gt; 0"> -->
            <xsl:value-of select="($line-width - $nominal-width) div $shrinkabilities" />
            <!-- </xsl:when> -->
          <!-- <xsl:otherwise> -->
            <!-- <xsl:value-of select="'UNDEFINED'" /> -->
            <!-- </xsl:otherwise> -->
          <!-- </xsl:choose> -->
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="calculate-cost">
    <xsl:param name="ratio" />

    <xsl:choose>
      <xsl:when test="$ratio = 'UNDEFINED' or $ratio &lt; -1">
        <xsl:value-of select="'INF'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="abs-ratio" select="($ratio &lt; 0)*(-$ratio) + ($ratio &gt; 0)*$ratio" />
        <xsl:value-of select="floor(100 * ($abs-ratio * $abs-ratio * $abs-ratio) + 0.5)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
