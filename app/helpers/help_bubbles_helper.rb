module HelpBubblesHelper


  def help_bubbles_ajax
    url = url_for(:controller => 'help_bubbles', :action => 'bubbles')
    ajax = <<-AJAX_END 
    document.observe('dom:loaded', function() {
        new Ajax.Request('#{url}', {
            method: 'get', 
            parameters: { bcont : '#{controller.controller_name}', bact : '#{controller.action_name}' },
            onSuccess: function(transport) { 
                var bubbles = transport.responseJSON;
                bubbles.each(function(b) {
                  try {
                    b['closeCallback'] = function(bub){ 
                                    new Ajax.Request("/help_bubbles/close", {
                                      parameters : { bcont : '#{controller.controller_name}', bact : '#{controller.action_name}', banch : bub.options.anchor }
                                    });
                                    return true; 
                    };
                    var bub = new HelpBubble(b);
                    if(b.hideOnClick) {
                      b.hideOnClick.each(function(elementId) {
                        Element.observe(elementId, "click", function() { bub.hide(); });
                      });
                    }
                  } catch (e) {
                  }
                });
              }
        });
      });
    AJAX_END
    javascript_tag(ajax)
  end


end
