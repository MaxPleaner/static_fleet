window.allowTextareaResizingInGrid = function($grid){
  textAreaChanged = function(node) {
    window.setTimeout(function(){
      gridStartup(".grid", ".box")
    }, 100)
    return true
  }
  
  $.each($grid.find("textarea"), function(idx, el) {
    $(el).on('mouseup mouseout', textAreaEvent)
  })
};
