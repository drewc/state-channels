import { pipe } from 'it-pipe'
import { map } from 'streaming-iterables'
import { toBuffer } from 'it-buffer'
import { fromString as uint8ArrayFromString } from 'uint8arrays/from-string'
import { toString as uint8ArrayToString } from 'uint8arrays/to-string'


  const StateChannels = globalThis.StateChannels;

  function State() {
    this.sequence = 0;
    this.assets = {}
    return this
  }
  
  State.prototype.deposit = function (name, amount) {
    return this.assets[name] = this.assets[name] || 0 + amount;
  }
  State.prototype.withdraw = function (name, amount) {
    return this.deposit(name, -Math.abs(amount));
  }
  State.prototype.transfer = function (from, to, amount) {
    this.withdraw(from, amount);
    return this.deposit(to, amount)
  }
  
  State.prototype.send = function (stream) {
    const vec = uint8ArrayFromString(JSON.stringify(this))
    // console.log("Sending ", this, ' as ', vec, ' over ', stream)
    return pipe([vec],stream)
  }
  
  State.prototype.recieve = function (stream) {
    let state ;
    return (async _ => {
      await pipe(stream,
                 async function (source) {
                   for await (const msg of source) {
                     state = uint8ArrayToString(msg.subarray())
                   }
                 }).then(_=> state)
    })()
  }
  State.prototype.protocol = '/state-channels/0.0.1';
  
  State.prototype.dial = function (peer) {
    return libp2p.dialProtocol(peer, this.protocol)
      .then(stream => {
        //console.log(peer.toString(), " has answered, giving it ", this)
        return this.send(stream) // pipe(
        //   [uint8ArrayFromString(JSON.stringify(this))],
        //   stream
        // )
      })
  }
  
  State.prototype.answer = function (conn) {
    const { connection, stream } = conn, { remotePeer } = connection;
    let remote_state;
    return pipe(
      stream,
      async function (source) {
        for await (const msg of source) {
          remote_state = uint8ArrayToString(msg.subarray())
        }
      }
    ).then(_=> JSON.parse(remote_state))
  }
  
  State.prototype.merge = function (new_state) {
    this.sequence = this.sequence + 1;
    console.log("Have assets: ", this.assets, " and new ", new_state)
    Object.assign(this.assets, new_state.assets);
    return this;
  }
  
  
  
  
  
  
    Object.assign(StateChannels, { state: new State() })

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
