rootdir = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{rootdir}/lib"

require 'test/unit'
require 'markdown'

# test all
class PreserveMathTest < Test::Unit::TestCase

  def test_preserve_math
    # $ ... $
    assert_to_html "<p>$a*b*c [a](b)$ $__a__ `b` a^b$</p>",
      '$a*b*c [a](b)$ $__a__ `b` a^b$'

    # $$ ... $$
    assert_to_html "<p>$$a*$b*c$$</p>",
      '$$a*$b*c$$'
  end

  def test_preserve_multiline_math
    src = '$$\begin{align} `x^2` \\\\
    y^2 \\\\
    \end{align}$$'
    assert_to_html "<p>$$\\begin{align} `x^2` \\\\    y^2 \\\\    \\end{align}$$</p>",
      src
  end

  def test_not_preserve_math
    # escaped dollar
    assert_to_html '<p>&#36;a<em>b</em>c <a href="b">a</a>&#36; &#36;<strong>a</strong> <code>b</code> a<sup>b</sup>$</p>',
      '\$a*b*c [a](b)\$ \$__a__ `b` a^b$'

    # code block
    assert_to_html "<pre><code>$[a](b)$\n</code></pre>",
      '    $[a](b)$'

    # inline code
    assert_to_html "<p><code>$</code>$</p>",
      '`$`$'

    # inline code with escaped dollar
    assert_to_html '<p><code>\$</code>$</p>',
      '`\$`$'

    # unclosed $$ (with warning)
    assert_to_html "<p>$$\\begin{align} <code>x^2</code>\\\ny<sup>2</sup>\nnothing</p>",
      "$$\\begin{align} `x^2`\\\\\ny^2\nnothing"
  end

  private

  def assert_to_html expected, md
    md = Markdown.new md, :preserve_math
    assert_equal expected, md.to_html.strip
  end
end
