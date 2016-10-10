function registerCurrentPage(window_location_search) {
  var command = window_location_search.slice(1).split("=")[0];
  return command;
}