function toggleVisibility($node){
  $node.toggleClass("toggled-close");
  $node.toggleClass("toggled-open");
}

function setAsInvisible($node){
  $node.addClass("toggled-close");
  $node.removeClass("toggled-open")
}

function toggleIndicatorOnSelectorText($node) {
  text = $node.text();
  words = text.split(" ");
  last_word = words[words.length - 1];
  is_last_word_open = (last_word == "⇣");
  if (is_last_word_open) {
    $node.text($node.text().replace(" ⇣", " ⇢"));
  } else {
    $node.text($node.text().replace(" ⇢", " ⇣"));
  }
}

function initIndicatorState($node) {
  $node.text($node.text() + " ⇢");
}

function selectorClickListener(event) {
  var $node = $(event.currentTarget);
  var $target = findTarget($node);
  toggleVisibility($target);
  toggleIndicatorOnSelectorText($node);
}

function findTarget($selector) {
  var targetSelector = $selector.attr("toggles");
  return $(targetSelector);
}

function initTogglers() {
  var $togglers = $('[toggles]');
  $.each($togglers, function(idx, elem){
    var $node = $(elem);
    var $target = findTarget($node);
    setAsInvisible($target);
    $node.on("click", selectorClickListener);
    initIndicatorState($node);
  });
}
