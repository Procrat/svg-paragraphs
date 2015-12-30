<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" indent="yes" />

  <xsl:template match="/document">
    <xsl:copy>
      <xsl:copy-of select="@*" />

      <xsl:for-each select="paragraph">
        <xsl:copy>
          <xsl:copy-of select="@*" />

          <!-- Find cascading align and font-size attributes -->
          <xsl:variable name="align">
            <xsl:value-of select="@align" />
            <xsl:if test="not(@align)"><xsl:value-of select="../@align" /></xsl:if>
          </xsl:variable>
          <xsl:variable name="font-size">
            <xsl:value-of select="@font-size" />
            <xsl:if test="not(@font-size)"><xsl:value-of select="../@font-size" /></xsl:if>
          </xsl:variable>

          <xsl:call-template name="make-glue-at-beginning">
            <xsl:with-param name="align" select="$align" />
            <xsl:with-param name="font-size" select="$font-size" />
          </xsl:call-template>

          <xsl:call-template name="tokenize">
            <xsl:with-param name="content" select="normalize-space(text())" />
            <xsl:with-param name="align" select="$align" />
            <xsl:with-param name="font-size" select="$font-size" />
          </xsl:call-template>

          <xsl:call-template name="make-glue-at-end">
            <xsl:with-param name="align" select="$align" />
            <xsl:with-param name="font-size" select="$font-size" />
          </xsl:call-template>
        </xsl:copy>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="tokenize">
    <xsl:param name="content" />
    <xsl:param name="align" />
    <xsl:param name="font-size" />
    <xsl:param name="delimiter" select="' '" />

    <xsl:choose>
      <xsl:when test="contains($content,$delimiter)">
        <xsl:call-template name="make-box">
          <xsl:with-param name="content" select="substring-before($content,$delimiter)" />
          <xsl:with-param name="font-size" select="$font-size" />
        </xsl:call-template>

        <xsl:call-template name="make-glue">
          <xsl:with-param name="align" select="$align" />
          <xsl:with-param name="font-size" select="$font-size" />
        </xsl:call-template>

        <xsl:call-template name="tokenize">
          <xsl:with-param name="content" select="substring-after($content,$delimiter)" />
          <xsl:with-param name="align" select="$align" />
          <xsl:with-param name="font-size" select="$font-size" />
          <xsl:with-param name="delimiter" select="$delimiter" />
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:call-template name="make-box">
          <xsl:with-param name="content" select="$content" />
          <xsl:with-param name="font-size" select="$font-size" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="make-box">
    <xsl:param name="content" />
    <xsl:param name="font-size" />

    <xsl:variable name="character-width" select="$font-size div 2" />

    <box width="{$character-width * string-length($content)}">
      <xsl:value-of select="$content" />
    </box>
  </xsl:template>

  <xsl:template name="make-glue">
    <xsl:param name="align" />
    <xsl:param name="font-size" />

    <xsl:variable name="nominal-glue-width" select="$font-size div 2" />
    <xsl:variable name="stretchability" select="3 * $nominal-glue-width div 2" />

    <xsl:choose>
      <xsl:when test="$align = 'justified'">
        <glue stretchability="{$stretchability}" shrinkability="0" width="{$nominal-glue-width}" />
      </xsl:when>
      <xsl:when test="$align = 'ragged'">
        <glue stretchability="{$stretchability}" shrinkability="0" width="0" />
        <penalty penalty="0" break="optional" />
        <glue stretchability="{-$stretchability}" shrinkability="0" width="{$nominal-glue-width div 2}" />
      </xsl:when>
      <xsl:when test="$align = 'centered'">
        <glue stretchability="{$stretchability}" shrinkability="0" width="0" />
        <penalty penalty="0" break="optional" />
        <glue stretchability="{-3 * $nominal-glue-width}" shrinkability="0" width="{$nominal-glue-width}" />
        <box width="0" />
        <penalty penalty="INF" break="prohibited" />
        <glue stretchability="{$stretchability}" shrinkability="0" width="0" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="make-glue-at-beginning">
    <xsl:param name="align" />
    <xsl:param name="font-size" />

    <xsl:variable name="nominal-glue-width" select="$font-size div 2" />
    <xsl:variable name="stretchability" select="3 * $nominal-glue-width div 2" />

    <xsl:choose>
      <xsl:when test="$align = 'justified'">
      </xsl:when>
      <xsl:when test="$align = 'ragged'">
      </xsl:when>
      <xsl:when test="$align = 'centered'">
        <glue stretchability="{$stretchability}" shrinkability="0" width="0" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="make-glue-at-end">
    <xsl:param name="align" />
    <xsl:param name="font-size" />

    <xsl:variable name="nominal-glue-width" select="$font-size div 2" />
    <xsl:variable name="stretchability" select="3 * $nominal-glue-width div 2" />

    <xsl:choose>
      <xsl:when test="$align = 'justified'">
        <penalty penalty="INF" break="prohibited" />
        <glue stretchability="INF" shrinkability="0" width="0" />
        <penalty penalty="-INF" break="required" />
      </xsl:when>
      <xsl:when test="$align = 'ragged'">
      </xsl:when>
      <xsl:when test="$align = 'centered'">
        <glue stretchability="{$stretchability}" shrinkability="0" width="0" />
        <penalty penalty="-INF" break="required" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
