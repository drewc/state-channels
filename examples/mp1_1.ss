(export #t)
(import ../src/runtime)
(import ../src/cli)
(import ../src/apimon)
(import ./mp1)

(import :gerbil/gambit/threads)

(define (main . args)
  ;; Creating the proc snapshots
  (define MP1 (micropay 'smith 10 'dupont 10 'durand 10))
  (define MP2 (micropay 'smith 10 'dupont 10 'durand 10))
  (define MP3 (micropay 'smith 10 'dupont 10 'durand 10))
  (define HOST1 Void)
  (define PR1 Void)
  (define PR2 Void)
  (define PR3 Void)
  (define GR1 Void)

  (##inline-host-statement "
  // console.log('Mpay', @1@, @scm2host@(@1@));
  window.GLO = @glo@" MP1)


  (##inline-host-declaration "
  window.StateChannels = { exit: false }")
  (##inline-host-statement
   "window.StateChannels.objs =
     { MP1: @1@ }"
   MP1)

  (def (call-method-using-string str obj . args)
    (apply mcall (string->symbol str) obj args))

(##inline-host-statement "
   window.StateChannels.cr = () => @async_call@(false, false, @2@, []);
    window.StateChannels.mcall = (meth, obj, ...args) => {
      const xargs = @host2scm@(args);
      return @async_call@(false, false, @1@,[@host2scm@(meth), obj, ...xargs])
    };" call-method-using-string cr)

(displayln "slot as well?: " (void? (method (typeof MP1) 'lsta))
           (unspecified? (: MP1 'lst)) "method" )

 (def (property-value obj name)
   (def sym (if (symbol? name) name (string->symbol name)))
   (def val (: obj name))
   (if (unspecified? val) (method (typeof obj) sym)))

 (##inline-host-statement "window.StateChannels.foreign = @host2foreign@")
 (##inline-host-statement
  "window.StateChannels.propertyValue = (obj, name) =>
     @async_call@(true, false, @1@, [obj, @host2scm@(name)])"
  property-value)
(begin
  (def (makeMicropay accounts)
    (def args '())
    (vector-for-each
     (lambda (v)
       (match v (#(str n)
                 (set! args (cons* n (string->symbol str) args)))))
     accounts)
    (set! args (reverse args))
    (let* ((mp (apply micropay args))
           (f  (##inline-host-expression "@host2foreign@(@1@)" mp)))
      (##inline-host-expression "@host2foreign@(@1@)" f)))
  (##inline-host-statement "
  window.StateChannels.makeMicropay = @scm2host@(@1@) "
                          makeMicropay))


(def (doublewrap obj)
   (##inline-host-expression "@host2foreign@(@host2foreign@(@1@))" obj))

(begin
  (def (slot-value obj name)
    (def sym (if (symbol? name) name (string->symbol name)))
    (def val (: obj sym))
    ;; (displayln "This is the obj: " obj " and sym " sym )
  #;(displayln "fudge? :"  val " and " (: obj sym)
              " but" (##inline-host-expression
                      "console.log('huh?',@1@, @scm2host@(@1@), '_y ', _stringp(@1@)) " val))
    (if (not (unspecified? val)) (doublewrap val)))
(##inline-host-statement
  "window.StateChannels.slotValue = (obj, name, scm = false) =>
     @async_call@(true, false, @1@, [obj, @host2scm@(name)])
        .then(r => { return scm ? r : @scm2host@(r); })"
  slot-value))
(begin
(def (slot-method? obj name)
  (def sym (if (symbol? name) name (string->symbol name)))
  (method (typeof obj) sym))
(##inline-host-statement
 "window.StateChannels.hasMethod = (obj, name) =>
   @async_call@(true, false, @1@, [obj, @host2scm@(name)])"
 slot-method?))


(begin ;; makeRexpr and the globalThis.StateChannels binding
  (def (makeRexpr type vslots)
    (def scm-type (if (string? type) (string->symbol type) type))
    (def slots '())
    (vector-for-each
     (lambda (v)
       (match v (#(n val)
                 (set! slots (cons* val (string->symbol n) slots)))))
     vslots)
    (set! slots (reverse slots))
    ;; (displayln "Slots: " slots)
    (doublewrap (rexpr scm-type `(,@slots))))

    (##inline-host-statement "
   // alert('inline');
  window.StateChannels.makeRexpr = @scm2host@(@1@) "
                             makeRexpr))

(begin
  (def (make-proch user uid)
    (def usym (if (string? user) (string->symbol user) user))
    (let ((h (proch 'USER usym 'UID uid)))
      ;;(displayln "Have Proch" h)
      (doublewrap h)))
  (##inline-host-statement "
globalThis.StateChannels.makeProcHost = (user, uid) =>
 @async_call@(true, false, @1@, [@host2scm@(user), @host2scm@(uid)]).then(h => {
    //console.log('Have return', h);
    return h
 });"
                           make-proch))

 (begin
   (##inline-host-statement "
 globalThis.StateChannels.currentProcHost = (proc = false) => {
   const scm = proc instanceof Rexpr ? proc.$scm : proc
   return @async_call@(false, false, @1@, proc ? [scm] : []);
};"
                            current-proch!))

  (##inline-host-statement "
  _async_call_scm = function (need_result, thread_scm, proc_scm, args_scm) {

  var promise = new Promise(function (resolve, reject) {

    function done(err, result) {
      if (err !== null) {
        reject(new Error(err));
      } else {
        resolve(result);
      }
    };

    args_scm.unshift(proc_scm);               // procedure to call

    if (need_result) {
      args_scm.unshift(_function2scm(done)); // Scheme callback for result
    } else {
      args_scm.unshift(_host2scm(false));    // no result needed
      done(null, _host2scm(void 0));         // cause #!void to be returned
    }

    args_scm.unshift(thread_scm);             // run in specific thread

    _callback_queue.write(args_scm);
  });

  return promise;
};
")
(begin
  (def (make-procla user uid self)
    (displayln "Make Procl" user uid self)
    (let ((h (procl 'USER user 'UID uid 'SELF self)))
      (displayln "Have Procl : " h)
      h
      #;(doublewrap h)))
    (##inline-host-statement "
globalThis.StateChannels.makeProcLa = (user, uid, self) => {
const { Rexpr } = StateChannels;
 const scm = self instanceof Rexpr ? self.$scm : self ;
 return @async_call_scm@(true, false, @1@,
  [@host2scm@(user), @host2scm@(uid), scm]);
};"
                           list)
  (##inline-host-statement "
globalThis.StateChannels.makeProcL = (user, uid, self) => {
const { Rexpr } = StateChannels;
 const scm = self instanceof Rexpr ? self.$scm : self ;
 return @async_call_scm@(true, false, @1@,
  [@host2scm@(user), @host2scm@(uid), scm]);
};"
                           make-procla))
 (begin
   (##inline-host-statement "
 globalThis.StateChannels.netEnter = (proc) => {
   const scm = proc instanceof Rexpr ? proc.$scm : proc
   return @async_call@(false, false, @1@, proc ? [scm] : []);
};"
                            net-enter))

(begin
  (def (make-ProcGroupAndAttach procs (first Void))
    (let ((h (apply proc-group+attach first procs)))
      ;;(displayln "Have Proch" h)
      (doublewrap h)))
  (##inline-host-statement "
globalThis.StateChannels.makeProcGroupAndAttach = (procs) => {
 const { Rexpr } = StateChannels;
 const scms = procs.map(self => self instanceof Rexpr ? self.$scm : self) ;
 return @async_call@(true, false, @1@, procs);
 };"
                           make-ProcGroupAndAttach))

(##inline-host-statement #<<EOF
function Rexpr (type = "@@rexpr", obj = {}) {
  const { makeRexpr } = StateChannels ;
  // console.log("Make Rexpr?", makeRexpr)
  if (!type) {
    this.$scm = obj
  } else if (typeof type === 'object' && !(type instanceof RexprType)) {
    this.$scm = type
  } else {
    makeRexpr(type, Object.entries(obj)).then(r => { this.$scm = r })
  }
  return this.proxify();
};

function RexprType(type) {
  Object.assign(this, type);
  return this;
}
const promiseProxy = (prom) => {
  return new Proxy(() => prom, {
    get: function(target, prop) {
      var value = target()[prop];
      return typeof value == 'function' ? value.bind(target()) : value;
    },
    apply: function(target, thisArg, argumentsList) {
      return target().then(f => {
        if (typeof f === 'function') {
          return f(...argumentsList)
        } else { return f }
      })
  }
  })
};

const makeRexprHandler = (obj) => {
   const proto = Object.getPrototypeOf(obj);
  return {
    getPrototypeOf(target) { return proto ; },
    get(target, prop, rec) {
     // console.log("target:", target)
      if (Object.hasOwn(target, prop) || prop.startsWith('$')) {
        console.warn("Accessing ", prop, " In", target)
         return Reflect.get(...arguments);
      } else {
      return promiseProxy(StateChannels.slotValue(target.$scm, prop)
        .then(val => typeof val !== "undefined" ? val :
              StateChannels.hasMethod(target.$scm, prop)
              .then(meth => {
                if (typeof meth === "undefined") {
                  Reflect.get(proto, prop, rec);
                } else {
                  return (...args) => StateChannels.mcall(prop, target.$scm, ...args);
                }
              })
             )
                         )
      }
    }
  }
}

const proxifyRexpr = (obj) => {
  const handler = makeRexprHandler(obj);
  const prox = new Proxy(obj, handler);
  return prox;
}

 Rexpr.prototype.proxify = function () {
    return proxifyRexpr(this);
 }


globalThis.StateChannels.Rexpr = Rexpr
Rexpr.prototype.$slot = function (id) {
  return StateChannels.slotValue(this.$scm, id, true)
}

function Micropay(...accounts) {
  const { makeMicropay , Rexpr } = StateChannels;
  this.$proxy = Rexpr.call(this, false);
  const self = this
  this.$promise = makeMicropay(accounts).then(m => {
    self.$scm = m
    return true
    }).catch((e) => { self.$error = e ; return false })
  Object.setPrototypeOf(this, Object.create(this.$proxy))
  return this
}
Micropay.prototype = Object.create(Rexpr.prototype);
Micropay.prototype.constructor = Micropay

globalThis.StateChannels.Micropay = Micropay;
function ProcHost(slots) {
  const { makeProcHost , Rexpr } = StateChannels;
  this.$proxy = Rexpr.call(this, false);
  this.$promise = makeProcHost(slots.user, slots.uid).then(m => {
    // console.log("Hve m ", m, "For This", this)
    this.$scm = m
    return true
    }).catch((e) => { this.$error = e ; return false })
  Object.setPrototypeOf(this, Object.create(this.$proxy))
  return this
}
ProcHost.prototype = Object.create(Rexpr.prototype);
ProcHost.prototype.constructor = ProcHost

globalThis.StateChannels.ProcHost = ProcHost;
function ProcL(slots) {
  const { makeProcL , Rexpr } = StateChannels;
  this.$proxy = Rexpr.call(this, false);
  this.$promise = makeProcL(slots.user, slots.uid, slots.self).then(m => {
    console.log("Have Procl ", m, "For This", this)
    this.$scm = m
    return true
    }).catch((e) => { this.$error = e ; throw e })
 // Object.setPrototypeOf(this, Object.create(this.$proxy))
  return this.$proxy
}
ProcL.prototype = Object.create(Rexpr.prototype);
ProcL.prototype.constructor = ProcL

globalThis.StateChannels.ProcL = ProcL;
function ProcGroupAndAttach(...procs) {
  const { makeProcGroupAndAttach , Rexpr } = StateChannels;
  this.$proxy = Rexpr.call(this, false);
  this.$promise = makeProcGroupAndAttach(procs).then(m => {
    // console.log("Hve m ", m, "For This", this)
    this.$scm = m
    return true
    }).catch((e) => { this.$error = e ; return false })
  Object.setPrototypeOf(this, Object.create(this.$proxy))
  return this
}
ProcGroupAndAttach.prototype = Object.create(Rexpr.prototype);
ProcGroupAndAttach.prototype.constructor = ProcGroupAndAttach

globalThis.StateChannels.ProcGroupAndAttach = ProcGroupAndAttach;
globalThis.main = async () => {
    // ;; Creating the proc snapshots
  const MP1 = new Micropay(["smith", 10], ["dupont", 10], ["durand", 10]),
        MP2 = new Micropay(["smith", 10], ["dupont", 10], ["durand", 10]),
        MP3 = new Micropay(["smith", 10], ["dupont", 10], ["durand", 10]);
  
  console.log("Have MPS:", MP1, MP2, MP3)
  let HOST1, PR1, PR2, PR3, GR1;
  const { cr } = StateChannels;
  await MP1.$promise; MP1.lst().then(cr); cr()
  await MP2.$promise; MP2.lst().then(cr);
  await MP3.$promise; MP3.lst().then(cr);
  
  let { currentProcHost, ProcHost } = StateChannels;
  
  HOST1 = new ProcHost({ name: "system", uid: "host1"});
  await HOST1.$promise ; currentProcHost(HOST1);
  
}
EOF
)
(def (call-to-exit?)
  (##inline-host-expression "@host2scm@(StateChannels.exit)"))

(def n 0)

  (let lp ()
    (let ((e? (call-to-exit?)))
     ; (displayln "Call to exit? " (call-to-exit?) " " n)
      (set! n (+ n 1))
      (if e? (displayln "Exiting...")
          (begin (##thread-sleep! 2)
                 (lp)))))

  (define (lstp . STATES)
    (outraw "---\n")
    (_lsp2 PR1)(cr)
    (_lsp2 PR2)(cr)
    (_lsp2 PR3)(cr)
    (if (not (empty? STATES))
      (begin
        (outraw "=>\n")
        (^ 'lst MP1)(cr)
        (^ 'lst MP2)(cr)
        (^ 'lst MP3)(cr))))

  ;; Displaying the snapshots
  (^ 'lst MP1)(cr)
  (^ 'lst MP2)(cr)
  (^ 'lst MP3)(cr)

  ;; Creating the host
  (set! HOST1 (proch 'USER 'system
                       'UID "HOST1"))
  (current-proch! HOST1)

  ;; Creating the procs
  (set! PR1 (procl 'USER "smith"
                   'UID "PR1"
                   'SELF MP1))
  (set! PR2 (procl 'USER "dupont"
                   'UID "PR2"
                   'SELF MP2))
  (set! PR3 (procl 'USER "durand"
                   'UID "PR3"
                   'SELF MP3))
  (net-enter PR1)
  (net-enter PR2)
  (net-enter PR3)

  (set! GR1 (proc-group+attach Void PR1 PR2 PR3))
  (:= GR1 'UID "GR1")
  (:= GR1 'USER "nobody")
  (outraw "---\n")
  (netlist 1)(cr)

  ;; Doing a micropayment
  (current-proc! PR1)
  (^ 'send (: PR1 'GROUP) 'transfer 'dupont 5)
  (lstp)

  (^ 'step PR1)
  (lstp)

  (^ 'step PR2)
  (lstp 1)

  (^ 'step PR1)
  (lstp 1)

  (^ 'step PR1)
  (lstp)

  (^ 'step PR3)
  (lstp 1)

  (^ 'step PR1)
  (lstp))

(displayln "Current tg: "
           (thread-group->thread-list (current-thread-group)))

;(main)
