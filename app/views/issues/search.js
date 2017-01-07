var $select = $("<%= escape_javascript(render 'pages/home_sort_select') %>");
$('#parties-all .parties-all .parties-filter .parties-sort-select').html($select);
parti_partial$($select);

$('#parties-all input[name=sort]').val("<%= params['sort'] %>");

var $issues = $("<%= escape_javascript(render 'issues/list') %>");
$('#parties-all .parties-all .parties-all-list').html($issues).one("parti-home-searched", function(e) {
  parti_ellipsis($('#parties-all .parties-all .parties-all-list'));
});
parti_partial$($issues);
