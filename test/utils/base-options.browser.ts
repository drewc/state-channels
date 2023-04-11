
import { webSockets } from '@libp2p/websockets'
import * as filters from '@libp2p/websockets/filters'
import { mplex } from '@libp2p/mplex'
import { plaintext } from '../../src/insecure/index.js'
import type { Libp2pOptions } from '../../src'
import mergeOptions from 'merge-options'

export function createBaseOptions (overrides?: Libp2pOptions): Libp2pOptions {
  const options: Libp2pOptions = {
    transports: [
      webSockets({
        filter: filters.all
      })
    ],
    streamMuxers: [
      mplex()
    ],
    connectionEncryption: [
      plaintext()
    ],
    relay: {
      enabled: false,
      hop: {
        enabled: false
      }
    },
    nat: {
      enabled: false
    }
  }

  return mergeOptions(options, overrides)
}
