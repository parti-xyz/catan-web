//  <h4>Tasks</h4>
//  <div data-controller="nested-form">
//    <template data-target="nested-form.template">
//      <%= form.fields_for :tasks, Task.new, child_index: 'NEW_RECORD' do |task| %>
//        <%= render "task_fields", form: task %>
//      <% end %>
//    </template>
//
//    <%= form.fields_for :tasks do |task| %>
//      <%= render "task_fields", form: task %>
//    <% end %>
//
//    <div class="mb-3" data-target="nested-form.links">
//      <%= link_to "Add Task", "#", class: "btn btn-outline-primary", data: { action: "click->nested-form#add_association" } %>
//    </div>
//  </div>
//
//  # _task_fields.html.erb
//  <%= content_tag :div, class: "nested-fields", data: { new_record: form.object.new_record? } do %>
//    <div class="form-group">
//      <%= form.label :description %>
//      <%= form.text_field :description, class: 'form-control' %>
//      <small><%= link_to "Remove", "#", data: { action: "click->nested-form#remove_association" } %></small>
//    </div>
//
//    <%= form.hidden_field :_destroy %>
//  <% end %>

import { Controller } from "stimulus"


export default class extends Controller {
  static targets = ["fields", "template"]

  addAssociation(event) {
    event.preventDefault()

    var content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.linksTarget.insertAdjacentHTML('beforebegin', content)
  }

  removeAssociation(event) {
    event.preventDefault()

    const nestedFieldWrapper = event.currentTarget.closest(`[data-target~="${this.identifier}.nestedFieldWrapper"]`)

    const paramMap = new ParamMap(this, nestedFieldWrapper)
    if (paramMap.get('newRecord') === 'true') {
      // New records are simply removed from the page
      nestedFieldWrapper.remove()
    } else {
      // Existing records are hidden and flagged for deletion
      nestedFieldWrapper.querySelector("input[name*='_destroy']").value = 1
      nestedFieldWrapper.style.display = 'none'
    }
  }
}