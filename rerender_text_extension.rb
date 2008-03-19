class RerenderTextExtension < Radiant::Extension
  version "1.0"
  description "A simple method that allows tags to rerender their contained content"
  url "http://github.com/AndrewO/rerender_text/tree/"
  
  def activate
    RerenderText
  end
  
  def deactivate
  end
end