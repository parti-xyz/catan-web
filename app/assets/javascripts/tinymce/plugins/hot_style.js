tinymce.PluginManager.add('hot-style', function(editor, url) {
  editor.ui.registry.addIcon('fa-paragraph', '<svg style="width: 12px; height: 20px;" viewBox="0 0 416 448"><path fill="currentColor" d="M448 48v32a16 16 0 0 1-16 16h-48v368a16 16 0 0 1-16 16h-32a16 16 0 0 1-16-16V96h-32v368a16 16 0 0 1-16 16h-32a16 16 0 0 1-16-16V352h-32a160 160 0 0 1 0-320h240a16 16 0 0 1 16 16z"></path></svg>');

  editor.ui.registry.addIcon('fa-level-down', '<svg class="icon" style="width: 12px; height: 20px;" viewBox="0 0 416 448"><path fill="currentColor" d="M313.553 392.331L209.587 504.334c-9.485 10.214-25.676 10.229-35.174 0L70.438 392.331C56.232 377.031 67.062 352 88.025 352H152V80H68.024a11.996 11.996 0 0 1-8.485-3.515l-56-56C-4.021 12.926 1.333 0 12.024 0H208c13.255 0 24 10.745 24 24v328h63.966c20.878 0 31.851 24.969 17.587 40.331z"></path></svg>');

  var style_map = {'p': '기본 스타일', 'h1': '제목1 스타일', 'h2': '제목2 스타일', 'h3': '제목3 스타일'}
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

    var options = {
      tooltip: style_map[tag],
      onAction: action,
      onSetup: setup
    }

    if(tag === "p") {
      options.icon = "fa-paragraph";
    } else {
      options.text = tag.toUpperCase();
    }


    editor.ui.registry.addToggleButton("style-" + tag, options);
  });

  editor.ui.registry.addButton("style-br", {
    tooltip: "줄바꿈",
    icon: "fa-level-down",
    onAction: function() {
      uniqueId = "___cursor___" + Math.random().toString(36).substr(2, 16);
      editor.execCommand('mceInsertContent', false, "<br/><cursorbr id=" + uniqueId + ">_</cursorbr> ");
      editor.selection.select(editor.dom.select('#' + uniqueId)[0]);
      editor.selection.collapse(0);
      editor.dom.remove(uniqueId);
    },
  });
});
