import TomSelect from "tom-select/dist/cjs/tom-select.popular";

/**
 * Overrides simple inputs in the resource permissions controller
 * Allows to use more than one group when configuring :civicrm_groups authorization handler
 */
/* eslint-disable no-new */
document.addEventListener("DOMContentLoaded", () => {

  /**
   * Multiselect to choose which participatory spaces should sync with Civicrm groups
   * */
  const spacesSelector = document.getElementById("civicrm-groups-participatory-spaces-selector");
  if (spacesSelector) {
    new TomSelect(spacesSelector, {
      plugins: ["remove_button", "dropdown_input"],
      valueField: "id",
      labelField: "text",
      searchField: "text",
      create: false,
      render: {
        option: (data, escape) => {
          return `<div>${escape(data.text)}</div>`;
        },
        item: (data, escape) => {
          return `<div>${escape(data.text)}</div>`;
        }
      },
      load: function (_query, callback) {
        const { url } = spacesSelector.dataset;
        if (this.loading > 1) {
          callback();
          return;
        }
        fetch(url).
          then((response) => response.json()).
          then((json) => {
            this.settings.load = null;
            callback(json);
          }).
          catch(() => callback());
      }  
    });
  }

  /**
   * Multiselect to transform ids separated by commas into a list of objects
   * */
  const groupSelectors = document.querySelectorAll("input[name$='[authorization_handlers_options][civicrm_groups][groups]'");
  const membershipSelectors = document.querySelectorAll("input[name$='[authorization_handlers_options][civicrm_membership_types][membership_types]'");
  const permissionsTomSelect = (input, url) => {
    new TomSelect(input, {
      plugins: ["remove_button", "dropdown_input"],
      valueField: "id",
      labelField: "text",
      searchField: "text",
      create: false,
      onInitialize: function() {
        fetch(`${url}?ids=${input.value}`, { headers: { "Accept": "application/json" } }).
          then((response) => response.json()).
          then((data) => {
            console.log(this, data);
            data.forEach((item) => {
              this.updateOption(item.id, item);
            });
          });
      },
      render: {
        option: (data, escape) => {
          console.log("option", data);
          return `<div>${escape(data.text)}</div>`;
        },
        item: (data, escape) => {
          return `<div>${escape(data.text)}</div>`;
        }
      },
      load: function (query, callback) {
        const params = new URLSearchParams({
          term: query
        });

        fetch(`${url}?${params}`, { headers: { "Accept": "application/json" } }).
          then((response) => response.json()).
          then((json) => callback(json)).
          catch(() => callback());
      }  
    });
  };

  if (groupSelectors.length > 0 && window.civicrmGroupsUrl) {
    groupSelectors.forEach((input) => {
      permissionsTomSelect(input, window.civicrmGroupsUrl);
    });
  }

  if (membershipSelectors.length > 0 && window.civicrmMembershipTypesUrl) {
    membershipSelectors.forEach((input) => {
      permissionsTomSelect(input, window.civicrmMembershipTypesUrl);
    });
  }
});
