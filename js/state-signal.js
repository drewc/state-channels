import { pipe } from 'it-pipe'
import StateChannels from './state-channels'

const { libp2p } = StateChannels;

function Signal (type = "sprout", data) {
  Object.assign(this, { type, data })
}

Signal.prototype.send = function (stream) {
  const vec = uint8ArrayFromString(JSON.stringify(this))
  // console.log("Sending ", this, ' as ', vec, ' over ', stream)
  return pipe([vec],stream)
}

Signal.prototype.recieve = function (stream) {
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
Signal.prototype.protocol = '/state-channels/0.0.2';

Signal.prototype.dial = function (peer) {
  return libp2p.dialProtocol(peer, this.protocol)
    .then(stream => {
      //console.log(peer.toString(), " has answered, giving it ", this)
      return this.send(stream) // pipe(
      //   [uint8ArrayFromString(JSON.stringify(this))],
      //   stream
      // )
    })
}

Signal.prototype.answer = function (conn) {
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




StateChannnels.Signal = Signal

export default { Signal }
