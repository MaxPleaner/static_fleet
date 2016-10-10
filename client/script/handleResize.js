function store(){
  this.x = this.offsetWidth;
  this.y = this.offsetHeight;
}

function textAreaEvent(){
  if (this.offsetWidth !== this.x || this.offsetHeight !== this.y) {
      textAreaChanged(this);
      store.call(this);
  }
  return true
}