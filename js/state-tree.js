function Vein (type, data) {
  Object.assign(this, { type, data })
  return this
}
function Leaf (veins, id = uuidv4) {
  const vs = veins instanceof Array ? veins : [veins]
  this.veins = vs;
  this.scrapes = []
  this.id = id
  return this;
}

function Scrape(nodeId, msg) {
  Object.assign(this { nodeId, msg });
  return this;
}

Leaf.prototype.scrape (nodeId, msg) {
  this.scrapes.push(new Scrape(...arguments))
}
 function currentChenille() {
   globalThis.StateChannels.chenilleContext
 }

 function currentTree() {
   globalThis.StateChannels.tree
 }

function uuidv4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}


function Branch(leaves) {
  const ls = leaves instanceof Array ? leaves : [leaves]
  this.leaves = ls
  return this;
}

Branch.prototype.sprout = function (leaf) {
  return this.leaves.push(leaf)
}
