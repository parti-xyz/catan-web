tinymce.PluginManager.add('hot-style', function(editor, url) {
  var style_map = {'p': '문단', 'h1': '제목1', 'h2': '제목2', 'h3': '제목3'}
  Object.keys(style_map).forEach(function(tag) {
    var action = function(buttonApi) {
      editor.execCommand('mceToggleFormat', false, tag);
    }

    var setup = function(buttonApi) {
      var self = this, setup = function() {
        editor.formatter.formatChanged(tag, function(state) {
          buttonApi.setActive(state);
        });
      };
      editor.formatter ? setup() : editor.on('init', setup);

      var editorNodeChangeCallback = function(eventApi) {
        buttonApi.setActive(eventApi.element.nodeName.toLowerCase() === tag);
      }
      editor.on('NodeChange', editorNodeChangeCallback);

      return function(buttonApi) {
        editor.off('NodeChange', editorNodeChangeCallback);
      }
    }

    editor.ui.registry.addToggleButton("style-" + tag, {
      tooltip: style_map[tag],
      text: tag.toUpperCase(),
      onAction: action,
      onSetup: setup
    });
  });

  editor.ui.registry.addButton("style-br", {
    tooltip: "줄바꿈",
    text: "BR",
    onAction: function() {
      uniqueId = "___cursor___" + Math.random().toString(36).substr(2, 16);
      editor.execCommand('mceInsertContent', false, "<br/><span id=" + uniqueId + "> </span> ");
      editor.selection.select(editor.dom.select('#' + uniqueId)[0]);
      editor.selection.collapse(0);
      editor.dom.remove(uniqueId);
    },
  });
});
