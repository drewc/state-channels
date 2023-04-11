import { kadDHT } from '@libp2p/kad-dht'
import type { Libp2pOptions } from '../../src/index.js'
import { createBaseOptions } from '../utils/base-options.js'

export function createRoutingOptions (...overrides: Libp2pOptions[]): Libp2pOptions {
  return createBaseOptions({
    dht: kadDHT({
      kBucketSize: 20
    })
  }, ...overrides)
}
