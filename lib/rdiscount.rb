# Discount is an implementation of John Gruber's Markdown markup
# language in C. It implements all of the language as described in
# {Markdown Syntax}[http://daringfireball.net/projects/markdown/syntax]
# and passes the Markdown 1.0 test suite. The RDiscount extension makes
# the Discount processor available via a Ruby C Extension library.
#
# == Usage
#
# RDiscount implements the basic protocol popularized by RedCloth and adopted
# by BlueCloth:
#   require 'rdiscount'
#   markdown = RDiscount.new("Hello World!")
#   puts markdown.to_html
#
# == Replacing BlueCloth
#
# Inject RDiscount into your BlueCloth-using code by replacing your bluecloth
# require statements with the following:
#   begin
#     require 'rdiscount'
#     BlueCloth = RDiscount
#   rescue LoadError
#     require 'bluecloth'
#   end
#
class RDiscount
  VERSION = '1.6.8'

  # Original Markdown formatted text.
  attr_reader :text

  # Set true to have smarty-like quote translation performed.
  attr_accessor :smart

  # Do not output <tt><style></tt> tags included in the source text.
  attr_accessor :filter_styles

  # Do not output any raw HTML included in the source text.
  attr_accessor :filter_html

  # RedCloth compatible line folding -- not used for Markdown but
  # included for compatibility.
  attr_accessor :fold_lines

  # Enable Table Of Contents generation
  attr_accessor :generate_toc

  # Do not process <tt>![]</tt> and remove <tt><img></tt> tags from the output.
  attr_accessor :no_image

  # Do not process <tt>[]</tt> and remove <tt><a></tt> tags from the output.
  attr_accessor :no_links

  # Do not process tables
  attr_accessor :no_tables

  # Disable superscript and relaxed emphasis processing.
  attr_accessor :strict

  # Convert URL in links, even if they aren't encased in <tt><></tt>
  attr_accessor :autolink

  # Don't make hyperlinks from <tt>[][]</tt> links that have unknown URL types.
  attr_accessor :safelink

  # Do not process pseudo-protocols like <tt>[](id:name)</tt>
  attr_accessor :no_pseudo_protocols

  # preseve $...$ math ouside code blocks, for mathjax process
  attr_accessor :preserve_math

  # Create a RDiscount Markdown processor. The +text+ argument
  # should be a string containing Markdown text. Additional arguments may be
  # supplied to set various processing options:
  #
  # * <tt>:smart</tt> - Enable SmartyPants processing.
  # * <tt>:filter_styles</tt> - Do not output <tt><style></tt> tags.
  # * <tt>:filter_html</tt> - Do not output any raw HTML tags included in
  #   the source text.
  # * <tt>:fold_lines</tt> - RedCloth compatible line folding (not used).
  # * <tt>:generate_toc</tt> - Enable Table Of Contents generation
  # * <tt>:no_image</tt> - Do not output any <tt><img></tt> tags.
  # * <tt>:no_links</tt> - Do not output any <tt><a></tt> tags.
  # * <tt>:no_tables</tt> - Do not output any tables.
  # * <tt>:strict</tt> - Disable superscript and relaxed emphasis processing.
  # * <tt>:autolink</tt> - Greedily urlify links.
  # * <tt>:safelink</tt> - Do not make links for unknown URL types.
  # * <tt>:no_pseudo_protocols</tt> - Do not process pseudo-protocols.
  # * <tt>:preserve_math - escape markdown syntax for $...$ before convert (@text is changed)
  #
  def initialize(text, *extensions)
    @text = text
    extensions.each { |e| send("#{e}=", true) }
    @text = Math[@text].preprocess if preserve_math
  end

  Math = Struct.new :src, :multiline, :lineno
  class Math
    def preprocess
      require 'strscan'
      self.lineno = 1
      self.multiline = []
      lines = src.lines.map do |line|
        self.lineno = lineno.succ
        if !multiline.empty?
          scan_continued_math line
        elsif line.start_with?('    ')
          line
        else
          scan_normal_line StringScanner.new line
        end
      end
      multiline.map!{|s| "#{s}\n" }
      lines += multiline
      lines.join
    end

    def scan_continued_math line
      math, rest = line.split '$$', 2
      if rest
        multiline << math
        r = escape! multiline.join
        r << '$$' << scan_normal_line(StringScanner.new rest)
        multiline.clear
        r
      else
        warn "#{lineno}: #{line.rstrip}\n\tAre we in the middle of multiline math? $$ not closed?" if line !~ /\\\\$/
        multiline << line.rstrip
        nil
      end
    end

    def scan_normal_line ss
      r = ''
      while s = (ss.scan(/`.+?`/) or scan_inline_math(ss) or scan_char(ss))
        r << s
      end
      r
    end

    def scan_inline_math ss
      if (s = ss.scan /(\$\$?).+?\1/)
        escape! s
      elsif (l = ss.scan /\$\$.+?\\\\$/)
        multiline << l
        ss.terminate
      end
      s
    end

    def scan_char ss
      c = ss.scan /\\[\\`$]|./m
      c == '\$' ? '&#36;' : c
    end

    def escape! s
      s.gsub! /([\\\[*_`^])/, "\\\\\\1"
    end
  end
end

Markdown = RDiscount unless defined? Markdown

require (RUBY_PLATFORM =~ /darwin/ ? 'rdiscount.bundle' : 'rdiscount.so')
