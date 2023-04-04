const StateChannels = globalThis.StateChannels;


  function Peer(detail = { id: "RemoteId",
                           stdin: "The stream to",
                           stdout: "The stream from",
                           libp2p: "the libp2p instance"
                         }
               )
{
    this.$sc = StateChannels;
    Object.assign(this, detail)
    const existing = this.exists()
    if (existing) {
      Object.assign(existing, this)
      return existing;
    } else return this.add();
}

  const peerExists = (detail, sc = StateChannels) => {
    return sc.peers.find(p => p.id === detail.id)
  }

  Peer.prototype.exists = function() {
    return peerExists(this, this.$sc)
  }

  const addPeer = (peer, sc = StateChannels) => {
    const pee = peer instanceof Peer ? peer : new Peer(peer);
    sc.peers.push(pee)
    return pee;
  }

  Peer.prototype.add = function () {
    return addPeer(this, this.$sc)
  }

  const findPeer = (id, $sc = StateChannels) => {
    const rid = typeof id === 'string' ? id : id.id;
    return $sc.peers.find(p => p.id === rid);
  };

  Peer.prototype.find = function (id) {
    if (id === undefined) { id = this.id }
    return findPeer(id, this.$sc);
  }


  Object.assign(StateChannels, {
    peers: [],
    addPeer(detail) {
      existing = peerExists(detail);
      return existing || addPeer(detail)
    },
    Peer,
    findPeer
  });

export default StateChannels;
