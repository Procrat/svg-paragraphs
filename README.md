SVG Paragraphs
==============

This little program creates paragraphs in SVG using the TeX line breaking
algorithm. It transforms some paragraphs defined in XML into an SVG, which is
also XML, with XSLT 1.0 templates.

In case you don't know XSLT, it's sort of a programming language (although I
have my doubts that it's actually Turing complete) *but defined in XML*. Yes,
you heard that right. Just when you thought that software development couldn't
get much worse than old versions of PHP, you hear this. You have to call
functions, well, "templates", like this:

```xslt
<xsl:call-template name="some-template">
  <xsl:with-param name="some-param-a" select="$some-variable-a" />
  <xsl:with-param name="some-param-b" select="$some-variable-b" />
</xsl:call-template>
```

Also note that, although I named those things variables, there is no concept of
mutability in XSLT. Neither do you have any sort of loops. The only thing you
can rely on are recursive template calls. Have a look at the code and feel free
to cry your eyes out.

Hey, I didn't voluntarily choose to do this. I had to do it for a course called
Document Processing at Ghent University.
