require File.join(File.dirname(__FILE__), "..", "spec_helper")

class Page
  desc %{Count number of paragraphs within expanded content}
  tag "count_paragraphs" do |tag|
    text = tag.expand
    num = text.scan(/<p>/).length
    
    rerender_text(text, :num => num)
  end
  
  desc %{Returns <p id="paragraph_count">(number of paragraphs)</p>}
  tag "paragraph_count" do |tag|
    # Poor man's Hpricot: count up <p>'s
    %{<p id="paragraph_count">#{tag.locals.num}</p>}
  end
end

describe Page, "with a rerender tag" do
  before(:each) do
    # Not sure why @page doesn't seem to be cleaning up itself
    Page.delete_all
    PagePart.delete_all

    @page = Page.new(:title => "Test Page", :slug => "test-page", :status_id => 100, :breadcrumb => "Test Page")
    rerender_text = %{
<r:count_paragraphs>
  <rr:paragraph_count/>
  <p>Foo</p>
  <p>Bar</p>
</r:count_paragraphs>}
    @page.parts << PagePart.new(:name => "body", :content => rerender_text)
    @page.save!
  end
  
  it "should render <rr:...> tags after others and those tags should have access to previously rendered text" do
    res = @page.render
    res.should have_tag('#paragraph_count', "2")
  end
end

# We'll need this for the more complicated test case below
module StringMixin
  def to_slug
    self.strip.downcase.gsub(/[^-a-z0-9~\s\.:;+=_]/, '').gsub(/[\s\.:;=+]+/, '-')
  end
end

unless String.method_defined? :to_slug
  String.send(:include, StringMixin)
end

class Page
  6.times do |i|
    tag "h#{i + 1}" do |tag|
      contents = tag.expand
      anchor = contents.to_slug
      @headers ||= []
      @headers << {:id => anchor, :text => contents}
      %{<h#{i + 1} class="header" id="#{anchor}">#{contents}</h#{i + 1}>}
    end
  end
  
  desc "Pulls out all of the headers in a page"
  tag "capture_headers" do |tag|
    rerender_text(tag.expand, :headers => @headers)
  end
  
  desc "Renders the page table of contents"
  tag "toc" do |tag|
    str = "<ul id='toc'>"
    tag.locals.headers.each do |header|
      str += %{<li><a href="##{header[:id]}">#{header[:text]}</a></li>}
    end
    str += "</ul>"
    str
  end
end

describe Page, "with a more complicated rerender tag" do
  before(:each) do
    # Not sure why @page doesn't seem to be cleaning up itself
    Page.delete_all
    PagePart.delete_all

    @page = Page.new(:title => "Test Page", :slug => "test-page", :status_id => 100, :breadcrumb => "Test Page")
    rerender_text = %{
<r:capture_headers>
  <rr:toc/>

<r:h1>Foo</r:h1>

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore
magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

<r:h2>Foo Bar</r:h2>

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore
magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

<r:h1>Baz</r:h1>

<r:h2>Baz Quux</r:h2>

<r:h3>Baz Quux Quuz</r:h3>

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore
magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

</r:capture_headers>
}
    @page.parts << PagePart.new(:name => "body", :content => rerender_text, :filter_id => "Textile")
    @page.save!
  end
  
  it "should add an id and class to all of the h1, h2, and h3 produce a list of page links" do
    res = @page.render
    res.should have_tag("#toc") do |el|
      el.should have_tag("a[href=#foo]", "Foo")
      el.should have_tag("a[href=#foo-bar]", "Foo Bar")
      el.should have_tag("a[href=#baz]", "Baz")
      el.should have_tag("a[href=#baz-quux]", "Baz Quux")
      el.should have_tag("a[href=#baz-quux-quuz]", "Baz Quux Quuz")
    end
  end
end
