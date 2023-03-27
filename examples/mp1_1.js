// ;; Creating the proc snapshots
const MP1 = new Micropay(["smith", 10], ["dupont", 10], ["durand", 10]),
      MP2 = new Micropay(["smith", 10], ["dupont", 10], ["durand", 10]),
      MP3 = new Micropay(["smith", 10], ["dupont", 10], ["durand", 10]);

console.log("Have MPS:", MP1, MP2, MP3)
let HOST1, PR1, PR2, PR3, GR1;
const { cr } = StateChannels;
await MP1.$promise; MP1.lst().then(cr);
await MP2.$promise; MP2.lst().then(cr);
await MP3.$promise; MP3.lst().then(cr);

let { currentProcHost, ProcHost } = StateChannels;

HOST1 = new ProcHost({ name: "system", uid: "host1"});
await HOST1.$promise ; currentProcHost(HOST1);


let { ProcL, netEnter } = StateChannels;
PR1 = new ProcL({ user: "smith", uid: "PR1", self: MP1})
PR2 = new ProcL({ user: "dupont", uid: "PR2", self: MP2})
PR3 = new ProcL({ user: "durand", uid: "PR3", self: MP3})

await PR1.$promise; netEnter(PR1);
await PR2.$promise; netEnter(PR2);
await PR3.$promise; netEnter(PR3);

console.log("ProcL", PR1, PR1.$promise)



let { ProcGroupAndAttach } = StateChannels;
GR1 = new ProcGroupAndAttach(PR1, PR2, PR3);

await GR1.$promise; console.log("GR1", GR1.$promise);
