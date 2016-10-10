
function routeFromCurrentPage(pagename) {
  var selector;
  if ((pagename == "show_script") || (pagename == "update_script")) {
    openSelectedScript()
  } else if (pagename == "run_script") {
    openSelectedScript()
    openLastRunScript()
  } else if ((pagename == "create_script") || (pagename == "delete_script")) {
    openListScripts()
  } else if (
    (pagename == "create_site")      ||
    (pagename == "build_empty_site") ||
    (pagename == "build_empty_site_with_genrb")
  ) {
    openSitesList()
  } else if (
    (pagename == "build_site") ||
    (pagename == "deploy_site") ||
    (pagename == "add_page") ||
    (pagename == "remove_page") ||
    (pagename == "get_file_or_dir") ||
    (pagename == "get_site") ||
    (pagename == "update_file")
  ) {
    openCurrentSite()
  }
}

function openSelectedScript() {
  selector = ".indented-header[toggles='#selected-script']"
  $(selector).trigger("click")
}

function openLastRunScript() {
  selector = ".indented-header[toggles='#last-run-script']"
  $(selector).trigger("click")
}

function openListScripts() {
  selector = ".indented-header[toggles='#list-scripts']"
  $(selector).trigger("click")
}

function openCurrentSite() {
  selector = ".indented-header[toggles='#current-site']"
  $(selector).trigger("click")
}

function openSitesList() {
  selector = ".indented-header[toggles='#sites-list']"
  $(selector).trigger("click")
}

function openSelectedSite() {
  selector = ".indented-header[toggles='#current-site']"
  $(selector).trigger("click")
}



