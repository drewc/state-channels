import { createLibp2p } from '@cerc-io/libp2p'
import { webSockets } from '@libp2p/websockets'
import { webRTCStar } from '@libp2p/webrtc-star'
import { noise } from '@chainsafe/libp2p-noise'
import { mplex } from '@libp2p/mplex'
import { bootstrap } from '@libp2p/bootstrap'

import StateChannels from './state-channels'

import { pipe } from 'it-pipe'
import { map } from 'streaming-iterables'
import { toBuffer } from 'it-buffer'
import { fromString as uint8ArrayFromString } from 'uint8arrays/from-string'
import { toString as uint8ArrayToString } from 'uint8arrays/to-string'

Object.assign(StateChannels, { pipe, uint8ArrayFromString })


document.addEventListener('DOMContentLoaded', async () => {
  const wrtcStar = webRTCStar()

  // Create our libp2p node
  const libp2p = await createLibp2p({
    start: false,
    connectionManager: {
  /**
   * The total number of connections allowed to be open at one time
   */
  maxConnections: 10,
  minConnections: 1,
    },
    addresses: {
      // Add the signaling server address, along with our PeerId to our multiaddrs list
      // libp2p will automatically attempt to dial to the signaling server so that it can
      // receive inbound connections from other peers
      listen: [
        '/dns4/wrtc-star1.par.dwebops.pub/tcp/443/wss/p2p-webrtc-star',
        '/dns4/wrtc-star2.sjc.dwebops.pub/tcp/443/wss/p2p-webrtc-star'
      ]
    },
    transports: [
     // webSockets(),
      wrtcStar.transport
    ],
    connectionEncryption: [noise()],
    streamMuxers: [mplex()],
    peerDiscovery: [
      wrtcStar.discovery //,
      // bootstrap({
      //   list: [
      //     '/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN',
      //     '/dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
      //     '/dnsaddr/bootstrap.libp2p.io/p2p/QmZa1sAxajnQjVM8WjWXoMbmPd7NsWhfKsPkErzpm9wGkp',
      //     '/dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa',
      //     '/dnsaddr/bootstrap.libp2p.io/p2p/QmcZf59bWwK5XFi76CZX8cbJ4BhTzzA3gU1ZjYZcYW3dwt'
      //   ]
      // })
    ]
  })

  // UI elements
  const status = document.getElementById('status')
  const output = document.getElementById('output')

  output.textContent = ''

  function log (txt) {
    console.info(txt)
     // output.textContent += `${txt.trim()}\n`
  }

   // Listen for new connections to peers
      libp2p.connectionManager.addEventListener('peer:connect', (evt) => {
        const connection = evt.detail, id = connection.remotePeer
        const { state, Peer } = StateChannels;
        console.log(`Connected to ${id}`, state)
        state.dial(id).then(_=> {
          const peer = new Peer({ id: id.toString(),
                                  connection
                                });
          return peer

          }). catch(e => connection.close())
        // libp2p.dialProtocol(id, '/state-channels/0.0.1')
         // .then(stream => {
        //    console.log(id.toString(), " has answered")

        // //   const newpeer = new StateChannels.Peer(
        // //     { id: id.toString(),
        // //       stdin: stream,
        // //       libp2p: libp2p
        // //     })
        //    pipe(
        //      [uint8ArrayFromString(JSON.stringify(state))],
        //      stream
        //    )
        // //   console.log ('sent ', state.send(stream));


        //    }).catch(e => connection.close() );

       // setTimeout(_=>{ connection.close() }, 100)
      })


       // Listen for new peers
   libp2p.addEventListener('peer:discovery', (evt) => {
     const peer = evt.detail, id = peer.id.toString()
     // console.log(`Found peer ${peer.id.toString()}`)

     if (StateChannels.findPeer(id)) {
       console.log("Already have this peer:", id)
       return false
     }


     // dial them when we discover them
     libp2p.dialProtocol(evt.detail.id, '/other-state-channels/0.0.1').then(stream => {

       //stream.close()
     }).catch(err => {
  //     log(`Could not dial ${evt.detail.id}`, err, peer)
     })
   });
   let conns = []
        // Listen for peers disconnecting
   libp2p.connectionManager.addEventListener('peer:disconnect', (evt) => {
     const connection = evt.detail
     console.log(`Disconnected from ${connection.remotePeer.toString()}`)
   })

   // Handle messages for the protocol
    var mylibp2phandler = libp2p.handle('/state-channels/0.0.1', async (conn) => {
      const { state } = StateChannels;
      return state.answer(conn).then (s => {
        state.merge(s)
        demoUI.displayState()
        console.log("Merged State:", state)
      });
      const { connection, stream } = conn, { remotePeer } = connection,
            peer = new StateChannels.Peer({
              id: remotePeer.toString(),
              stdout: stream,
              libp2p
            })

      console.log("handling/answering dial", remotePeer.toString())
      pipe(
            stream,
            async function (source) {
              for await (const msg of source) {
                console.log(uint8ArrayToString(msg.subarray()))
              }
            }


       )
      pipe(
         [uint8ArrayFromString('from 2 to 1')],
         stream
       )


    })

  status.innerText = 'StateChannels started!'
  console.log(`libp2p id is ${libp2p.peerId.toString()}`)

  var { StateChannels } = globalThis;
  StateChannels.state.deposit(libp2p.peerId.toString(), 0)

  // Export libp2p to the window so you can play with the API
  globalThis.libp2p = libp2p
  StateChannels.libp2p = libp2p

})
