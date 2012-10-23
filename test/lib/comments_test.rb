# -*- encoding : utf-8 -*-
require 'test_helper'

class CommentsTest < ActiveSupport::TestCase
  test "formatize_should_correctly_translate_known_tags" do
    t = "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\nAdemás tengo saltos de línea, [~dharana], [flag=es], [img]http://domain.test[/img] y [url=http://otherdomain.test]enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote]"
    t_formatized = "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />\nAdemás tengo saltos de línea, <a href=\"/miembros/dharana\">dharana</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img src=\"http://domain.test\" /> y <a href=\"http://otherdomain.test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>mwahwahwa</blockquote>"
    assert_equal t_formatized, Comments.formatize(t)
  end

  test "formatize user login" do
    expected = (
        "<span class=\"user-login\"><a href=\"/miembros/nagato\">nagato</a>" +
        "</span>")
    assert_equal expected, Comments.formatize("@nagato")
  end

  test "formatize spoiler" do
    expected = (
        "<span class=\"spoiler\">spoiler <span class=\"spoiler-content" +
        " hidden\">el mayordomo</span></span>")
    assert_equal expected, Comments.formatize("[spoiler]el mayordomo[/spoiler]")
  end

  test "unformatize user login" do
    formatized_comment = (
        "hello <span class=\"user-login\"><a href=\"/miembros/nagato\">nagato</a>" +
        "</span>!")
    assert_equal "hello @nagato!", Comments.unformatize(formatized_comment)
  end

  test "unformatize_should_correctly_translate_known_tags" do
    t_unformatized = (
        "Hola Mundo![b]me siento negrita[/b] y ahora..[i]CURSIVA!!![/i]\n" +
        "Además tengo saltos de línea, [~dharana], [flag=es]," +
        " [img]http://domain.test[/img] y [url=http://otherdomain.test]" +
        "enlaces!![/url]>>>Ownage!<<<[quote]mwahwahwa[/quote][code=python]foo" +
        "[/code][spoiler]foo[/spoiler]")

    t = (
        "Hola Mundo!<b>me siento negrita</b> y ahora..<i>CURSIVA!!!</i><br />" +
        "Además tengo saltos de línea, <a href=\"/miembros/dharana\">dharana" +
        "</a>, <img class=\"icon\" src=\"/images/flags/es.gif\" />, <img" +
        " src=\"http://domain.test\" /> y <a href=\"http://otherdomain." +
        "test\">enlaces!!</a>&gt;&gt;&gt;Ownage!&lt;&lt;&lt;<blockquote>" +
        "mwahwahwa</blockquote><pre class=\"brush: python\">foo</pre><span" +
        " class=\"spoiler\">spoiler <span class=\"spoiler-content hidden\">foo" +
        "</span></span>")

    assert_equal t_unformatized, Comments.unformatize(t)
  end


  test "formatize should properly formatize code tags" do
    assert_equal "<pre class=\"brush: js\">hola[]</pre>", Comments.formatize("[code]hola[][/code]")
    assert_equal "<pre class=\"brush: js\">hola \n*argv[]</pre>", Comments.formatize("[code]hola \n*argv[][/code]")

    assert_equal "<pre class=\"brush: cpp\">\nint main(int argc, char *argv[]) { }</pre>", Comments.formatize("[code=cpp]\nint main(int argc, char *argv[]) { }[/code]")

    assert_equal "<pre class=\"brush: python\">hola</pre>", Comments.formatize("[code=python]hola[/code]")
    assert_equal "<pre class=\"brush: js\">hola\n  mundo</pre>", Comments.formatize("[code]hola\n  mundo[/code]")
  end

  test "should formatize 2 urls in the same line" do
    assert_equal "<a href=\"http://example.com/1\">hello</a> <a href=\"http://example.com/2\">world</a>", Comments.formatize("[url=http://example.com/1]hello[/url] [url=http://example.com/2]world[/url]")
  end

  test "should fix incorrectly nested bbcodes" do
    assert_equal "[b]hola[/b]", Comments.fix_incorrect_bbcode_nesting("[b]hola")
    assert_equal '[B]hola[/B]', Comments.fix_incorrect_bbcode_nesting('[B]hola')
    assert_equal "[URL=http://google.com]hola[img]aa[/img][/URL]", Comments.fix_incorrect_bbcode_nesting('[URL=http://google.com]hola[img]aa[/img]')
    assert_equal '[URL=http://google.com]hola[img]aa[/img][img][/img][img][/img][/URL]', Comments.fix_incorrect_bbcode_nesting('[URL=http://google.com]hola[img]aa[/img][/img][/img]')
  end

  test "xss1 in url tag" do
    assert_equal(
      "[url=blag\" onclick=\"alert('foo');]Click me![/url]",
      Comments.formatize("[url=blag\" onclick=\"alert('foo');]Click me![/url]"))
  end

  test "xss2 in url tag" do
    assert_equal(
      "[url=blag\" onclick=\"alert('foo');]Click me![/url]",
      Comments.formatize("[url=blag\" onclick=\"alert('foo');]Click me![/url]"))
  end

  test "xss3 in url tag" do
    assert_equal(
        "<a href=\"http://example.com/\">Click me!\"&gt;&lt;script" +
        " type=\"text/javascript\"&gt;&lt;/script&gt;</a>",
      Comments.formatize(
          "[url=http://example.com/]Click me!\"><script type=" +
          "\"text/javascript\"></script>[/url]"))
  end

  test "invalid img tag" do
    invalid_img_tag = (
        "[img]http://www.frank151.com/wp-content/uploads/2009/07/chief_wiggum" +
        ".png\" onload=\"alert('foo');[/img]")
    assert_equal invalid_img_tag, Comments.formatize(invalid_img_tag)
  end

  # TODO
  def test_fix_incorrect_bbcode_nesting
    assert_equal '', Comments.fix_incorrect_bbcode_nesting('')
    assert_equal 'hola', Comments.fix_incorrect_bbcode_nesting('hola')
    assert_equal '[b]hola[/b]', Comments.fix_incorrect_bbcode_nesting('[b]hola[/b]')
    assert_equal '[b][i]hola[/i][/b]', Comments.fix_incorrect_bbcode_nesting('[b][i]hola[/i][/b]')

    assert_equal '[b][i]hola[/i][/b]', Comments.fix_incorrect_bbcode_nesting('[b][i]hola[/b][/i]')
    assert_equal 'hola', Comments.fix_incorrect_bbcode_nesting('hola[/b]')
    assert_equal '[url=http://gamersmafia.com]hola[/url]', Comments.fix_incorrect_bbcode_nesting('[url=http://gamersmafia.com]hola[/url]')
    assert_equal '[b]hola[/b] adios', Comments.fix_incorrect_bbcode_nesting('[b]hola[/b] adios')
    assert_equal '[i][b]hola[/b] [b]adios[/b][/i]', Comments.fix_incorrect_bbcode_nesting('[i][b]hola[/b] [b]adios[/b][/i]')
  end

  test "sicario_cannot_edit_comments_of_own_district" do
    u59 = User.find(59)
    bd = BazarDistrict.find(1)
    bd.add_sicario(u59)
    n65 = News.find(65)
    c = Comment.new(
        :content_id => n65.unique_content.id,
        :user_id => 1,
        :host => '127.0.0.1',
        :comment => 'comentario')
    assert c.save
    assert !c.can_edit_comment?(u59)
  end

  test "should replace all urls in a line" do
    assert_equal(
        "<a href=\"foo\">fóo</a> <a href=\"bar\">bAr</a>",
        Comments.formatize('[url=foo]fóo[/url] [url=bar]bAr[/url]'))
  end
end
