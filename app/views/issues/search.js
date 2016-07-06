var $select = parti_origin_partial("<%= escape_javascript(render 'pages/home_sort_select') %>");
$('#parties-all .parties-all .parties-filter .parties-sort-select').html($select);
$('#parties-all input[name=sort]').val("<%= params['sort'] %>");
var $issues = parti_origin_partial("<%= escape_javascript(render 'issues/list') %>");
$('#parties-all .parties-all .parties-all-list').html($issues).one("parti-home-searched", function(e) {
  parti_ellipsis($('#parties-all .parties-all .parties-all-list'));
});
