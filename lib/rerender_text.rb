module RerenderText
  include Radiant::Taggable
  
  desc %{
    Use this to render the contained content twice
    
    Usage:
    <pre><code><r:rerender [prefix="rr"]>...</r:rerender></code></pre>
  }
  tag "rerender" do |tag|
    prefix = tag.attr["prefix"] || "rr"
    rerender_text_with_prefix(tag.expand, prefix)
  end
  
  def rerender_text(text, options = {})
    rerender_text_with_prefix(text, "rr", options)
  end
  
  def rerender_text_with_prefix(text, prefix, options = {})
    _context = RerenderContext.new(self, text, options)
    _parser = Radius::Parser.new(_context, :tag_prefix => prefix)
    new_text = _parser.parse(text)
    
    new_text
  end
  
  # Indentical to the standard Radiant PageContext except that it captures previously rendered data and saves
  # it as a tag global variable, and can also take a hash of data that contained tags will use.
  class RerenderContext < PageContext
    def initialize(page, text, options)
      super(page)
      globals.previous_text = text
      options.each do |k, v|
        globals.send("#{k}=".to_s, v)
      end
    end
  end
end



class Page
  include RerenderText
end