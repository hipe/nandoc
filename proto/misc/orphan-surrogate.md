## <%= @item.nandoc_title %>

<% cx = @item.nandoc_sorted_visible_children %>
<% cx.each do |item| %>
* <%= link_to(item.nandoc_title, item.path) %>
<% end %>
