var $issues = parti_origin_partial("<%= escape_javascript(render 'issues/list') %>");
$('#parties-all .parties-all .parties-all-list').html($issues);
