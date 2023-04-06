globalThis.demoUI = {
  onChange(event, key) {
    console.log("Chasnerf:", event.target.value)
    StateChannels.state.assets[key] = event.target.value
    // TODO: This should be automated based on events
    // and internal to StateChannels. For now:
    StateChannels.peers.map(p => {
      StateChannels.state.dial(p.connection.remotePeer)
    })
  },
  createStateElement (state = StateChannels.state) {
  const tbl = document.createElement('table');
  Object.keys(state.assets).forEach(k => {
    var inp = document.createElement('input'),
        tr = document.createElement('tr'),
        as = state.assets,
        name = document.createTextNode(k),
        td1 = document.createElement('td'),
        td2 = document.createElement('td')
    inp.value = as[k];
    inp.onchange = e => demoUI.onChange(e, k);

      // console.log("Input:", inp, " val", inp.value)

    td1.appendChild(name); tr.appendChild(td1);
    td2.appendChild(inp); tr.appendChild(td2);
    tbl.appendChild(tr)
  })
  console.log(tbl);
  return tbl;
  },
  displayState(sel = '#status') {
    const myNode = document.querySelector(sel);
    while (myNode.firstChild) {
      myNode.removeChild(myNode.lastChild);
    }
    myNode.appendChild(demoUI.createStateElement())

  }
}
