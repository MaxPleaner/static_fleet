function gridStartup(gridSelector, itemSelector) {
  var elem = document.querySelector(gridSelector);
  var iso = new Isotope( elem, {
    itemSelector: itemSelector,
    layoutMode: 'fitRows'
  });
}


