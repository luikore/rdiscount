# encoding: UTF-8

rootdir = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{rootdir}/lib"

require 'test/unit'
require 'markdown'

# test all
class PreserveMathTest < Test::Unit::TestCase

  def test_math_scanner
    require 'strscan'
    m = RDiscount::Math.new
    assert_equal '- $L$', (m.scan_normal_line StringScanner.new '- $L$')
  end

  def test_preserve_math
    # preserve (bold / link / italic / inline code / sup) between $ ... $
    assert_to_html "<p>$a*b*c [a](b)$ $__a__ `b` a^b$</p>",
      '$a*b*c [a](b)$ $__a__ `b` a^b$'

    # escaped $
    assert_to_html '<p>$\$$</p>',
      '$\$$'

    # escaped \\
    assert_to_html "<p>$\\\\$$</p>",
      '$\\\\$$'

    # NOTE this is not valid latex, just to test $...$ inside $$...$$ should do no harm
    assert_to_html "<p>$$a*b*$*c*$*d$$</p>",
      '$$a*b*$*c*$*d$$'

    # list
    assert_to_html "<ul>\n<li><p>$L$ $*B*$</p></li>\n<li><p>hi</p></li>\n</ul>",
      "\n- $L$ $*B*$\n\n- hi"
  end

  def test_preserve_multiline_math
    src = '$$\begin{align} `x^2` \\\\
    y^2 \\\\
    \end{align}$$'
    assert_to_html "<p>#{src.gsub "\n", ''}</p>", src
  end

  def test_preserve_math_with_unicode
    src = '老师向同学们讲授了$年利率=月利率^12$的计算方法'
    assert_to_html "<p>#{src}</p>", src

    src = '老师向同学们讲授了$$年利率=月利率^12的计算方法'
    assert_to_html "<p>老师向同学们讲授了$$年利率=月利率<sup>12</sup>的计算方法</p>", src
  end

  def test_not_preserve_math
    # escaped dollar
    assert_to_html '<p>\$a<em>b</em>c <a href="b">a</a>\$ \$<strong>a</strong> <code>b</code> a<sup>b</sup>$</p>',
      '\$a*b*c [a](b)\$ \$__a__ `b` a^b$'

    # 4 spaces: code block
    assert_to_html "<pre><code>$[a](b)$\n</code></pre>",
      '    $[a](b)$'

    # inline code
    assert_to_html "<p><code>$$</code>$</p>",
      '`$$`$'

    # inline code with escaped dollar
    assert_to_html '<p><code>\$</code>$</p>',
      '`\$`$'

    # unclosed $$ (with warning)
    assert_to_html "<p>$$\\begin{align} <code>x^2</code>\\\ny<sup>2</sup>\nnothing</p>",
      "$$\\begin{align} `x^2`\\\\\ny^2\nnothing"
  end

  def test_preserve_math_not_change_default_inline_code_behavior
    %w[`\` `\\\\`].each do |src|
      assert_equal Markdown.new(src).to_html, Markdown.new(src, :preserve_math).to_html
    end
  end

  private

  def assert_to_html expected, md
    md = Markdown.new md, :preserve_math
    assert_equal expected, md.to_html.strip
  end
end
