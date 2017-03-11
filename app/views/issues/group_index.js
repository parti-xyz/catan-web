$("[data-action='parti-filter-parties']").removeClass('active');
<% if params[:category].present? %>
$("[data-action='parti-filter-parties'][data-search-category='<%= params[:category] %>']").addClass('active');
<% else %>
$("[data-action='parti-filter-parties'][data-search-category='']").addClass('active');
<% end %>

<% if params[:sort].present? %>
$("[data-action='parti-filter-parties'][data-search-sort='<%= params[:sort] %>']").addClass('active');
<% end %>

$('#parties-all input[name=sort]').val("<%= params['sort'] %>");
$('#parties-all input[name=category]').val("<%= params['category'] %>");

var $issues = $("<%= escape_javascript(render 'issues/page') %>");
$('#parties-all .parties-all .parties-all-list').html($issues).one("parti-home-searched", function(e) {
  parti_ellipsis($('#parties-all .parties-all .parties-all-list'));
});
parti_partial$($issues);
