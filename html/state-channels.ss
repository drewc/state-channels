(export #t)
(import ../src/runtime)
(import ../src/cli)
(import ../src/apimon)
(import ../examples/mp1)

(import :gerbil/gambit/threads)

(##inline-host-declaration #<<EOF
globalThis.StateChannels = {
  exit: false,
  heap: {}
}
Object.assign(StateChannels, {
  rexpr2host(rexpr) {
  return new StateChannels.Rexpr(false, rexpr)
  },
  scm2host(scm) {
    const { rexpr_type, old_scm2host, rexpr2host } = StateChannels;
    if (scm instanceof @Pair@ && typeof rexpr_type(scm) === 'string') {
      return rexpr2host(scm);
    } else if (scm instanceof Rexpr) {
      return scm;
    } else {
      return @scm2host@(scm)
    }
  },
  host2scm(host) {
    if (host instanceof Rexpr) {
      return host.$scm;
    } else {
      return host2scm(host)
    }
  }
});


Object.assign(StateChannels, {
  listp(obj) { return obj instanceof @Pair@ || obj === null },
  consp(obj) { return obj instanceof @Pair@ },
  car(obj) { return StateChannels.consp(obj) && obj.a },
  cdr(obj) { return StateChannels.consp(obj) && obj.b },
  symbolp(obj) { return obj instanceof @ScmSymbol@ },
  symbol_name(obj) { return StateChannels.symbolp(obj) && obj.a },
  asym_get(kons, key) {
    const { consp, car, cdr, symbolp, symbol_name, asym_get } = StateChannels;
    if (!consp(kons)) { return };
    let kar = car(kons); if (!consp(kar)) {return};
    if (symbolp(car(kar)) && symbol_name(car(kar)) === key) {
      return cdr(kar)
    } else {
      return asym_get(cdr(kons), key)
    }
  }
})


globalThis.StateChannels.makeRexpr = () => {
    alert('should later be a scm tranny')
     return new Promise((r) => {
      (function () { console.log(new Error().stack) })()
      r(true)
      })
 }                                 ;


(_=> {
  Object.assign(globalThis.StateChannels, {
    newPromiseProxy(prom) {
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
    }
  });

})();
(_=> {
StateChannels.rexpr_type = ($scm) => {
  const { car, asym_get } = StateChannels;
  const t = car(asym_get($scm, ":TYPE"));
  return @scm2host@(car(asym_get(t, ":NAME")))
}

function RexprType () { return this };

function Rexpr (type = "@@rexpr", obj = {}) {
  const { makeRexpr, rexpr_type } = StateChannels,
        self = this;
  if (!type && obj) {
    this.$type = rexpr_type(obj);
    this.$scm = obj
  } else if (typeof type === 'object' && !(type instanceof RexprType)) {
    this.$type = rexpr_type(type);
    this.$scm = type
  } else if (!obj) {
    null
  } else {
    makeRexpr(type, Object.entries(obj)).then(r => {
      this.$type = rexpr_type(r);
      this.$scm = r })
  }
  const pxy = new Proxy(function Rexpr() { return self }, this.handler)
  this.$proxy = pxy;
  const poll_$scm = (resolve) => {
    if (self.$scm === undefined ) {
      setTimeout(poll_$scm, 10, resolve)
    } else {
      return resolve(self.$scm ? pxy : false)
    }
  }
  this.$promise = new Promise(r => poll_$scm(r))
  return this.$proxy;
};


Object.assign(Rexpr.prototype, {
  getter(target, prop, receiver) {
    const { newPromiseProxy, property_value, scm2host} = StateChannels;
    if (Object.hasOwn(target, prop) || prop.startsWith('$')) {
         return Reflect.get(...arguments);
    }

    else {
      return newPromiseProxy(property_value(target, prop))
                            // .then(o => { return scm2host(o) }))
    }
  }
});

Object.assign(Rexpr.prototype, {
  apply(target, $this, args) {
   // console.log('Apply?', ...arguments)
    return target.$promise
  }
});


Object.assign(Rexpr.prototype, {
  handler: {
    getPrototypeOf(return_target) {
      return Object.getPrototypeOf(return_target())
    },
    get(return_target, prop, rec) {
      if (prop === 'then') { return undefined }
      const self = return_target()
      return self.getter(self, prop, rec)
    },
    apply(rt, th, args) { return rt().apply(rt(), th, args) }
  }
});

  globalThis.StateChannels.Rexpr = Rexpr
})();

EOF
)

(define (main . args)

  (def (place-on-heap obj (pointer (gensym)))
    (##inline-host-expression "(_=> {
    const { heap } = StateChannels;
    const p = @scm2host@(@2@);
    heap[p] = @1@;
    return p
  })();
  "
                             obj pointer
  ))
  
  (begin
    (def (fncall f . args) (place-on-heap (apply f args)))
    (let ((fn fncall))
      ;;(displayln "passing to js:" fn fncall)
    (##inline-host-statement "
  globalThis.StateChannels.funcall = (f, ...args) => {
    const { heap, fncall } = StateChannels;
    return @async_call@(true, false, fncall, [f, ...args]).then(p => {
      const pointer = p instanceof @Scheme@ ? p.a : p,
            ret = heap[pointer]
      delete heap[pointer]
      return ret
    });
  }" )));
  
  (##inline-host-statement "globalThis.StateChannels.fncall = @1@"
                             fncall)
  (place-on-heap ['foo 'bar 'baz])
  (fncall list 1 2 42)

(def (slot-value obj name)
  (let* ((sym (if (symbol? name) name (string->symbol name)))
         (val (: obj sym)))
    (if (not (unspecified? val)) val)))

(##inline-host-statement #<<EOF
 Object.assign(globalThis.StateChannels, {
   slot_value(obj, name, translate = false) {
     const { funcall, scm2host, Rexpr } = StateChannels,
           scm_slot_value = @1@,
           scm_obj = obj instanceof Rexpr ? obj.$scm : obj,
           scm_name = @host2scm@(name);
 
     return funcall(scm_slot_value, scm_obj, scm_name).then(v => {
       //  console.log('have slot value', v, scm2host(v))
       return translate ? scm2host(v) : v
     })
   }
 });
EOF
slot-value)

(def (find-rexpr-method rexpr name)
  (def sym (if (symbol? name) name (string->symbol name)))
  ;; (displayln "looking for " sym " method in " rexpr)
  (let ((m (method (typeof rexpr) sym)))
    ;; (displayln "Found " m " in " (typeof rexpr))
    m))
(##inline-host-statement #<<EOF
 Object.assign(globalThis.StateChannels, {
   find_method(obj, name) {
     const { funcall, Rexpr } = StateChannels,
           scm_find_method = @1@,
           scm_obj = obj instanceof Rexpr ? obj.$scm : obj,
           scm_name = @host2scm@(name);
 
     return funcall(scm_find_method, scm_obj, scm_name).then(v => {
       return v ? v : undefined
     })
   }
 });
EOF
find-rexpr-method
)

(begin
  (def (makeMicropay accounts)
    (def args '())
    (vector-for-each
     (lambda (v)
       (match v (#(str n)
                 (set! args (cons* n (string->symbol str) args)))))
     accounts)
    (set! args (reverse args))
    (apply micropay args))
  (##inline-host-statement
   "globalThis.StateChannels.makeMicropay = (accounts) => {
     const { funcall } = StateChannels;
     return funcall(@1@, @host2scm@(accounts))
}" makeMicropay)

  )

(##inline-host-statement #<<EOF
 Object.assign(globalThis.StateChannels, {
   call_method(meth, obj, ...args) {
     const { find_method, host2scm, funcall, Rexpr } = StateChannels,
           scm_obj = obj instanceof Rexpr ? obj.$scm : obj,
           scm_args = args.map(host2scm)
     if (typeof meth === 'string') {
       return find_method(scm_obj, meth).then(m => {
         return !m ? error("Method not found") : m
       })
     } else { return funcall(meth, scm_obj, ...scm_args) }
   }
 });
 

 Object.assign(globalThis.StateChannels, {
   property_value(obj, name, translate = false) {
     const { slot_value, find_method, call_method, scm2host } = StateChannels
     return slot_value(obj, name, translate).then(sv => {
       if (sv === undefined) {
         return find_method(obj, name).then(meth => {
           if (!meth) {
             return obj[name]
           } else {
             return (...args) => {
               return call_method(meth, obj, ...args)
             }
           }
         })
       } else { return scm2host(sv) }
     })
   }
 })
 
 
 
 

   function Micropay(...accounts) {
     const { makeMicropay , Rexpr, rexpr_type } = StateChannels
     return makeMicropay(accounts).then(mp => {
       console.log('Got mp', mp);
       return new Rexpr(false, mp)
     });
   }
 
 //  Micropay.prototype.constructor = Micropay
 
   globalThis.StateChannels.Micropay = Micropay;
 

EOF
)

  ;; Creating the proc snapshots
  (define MP1 (micropay 'smith 10 'dupont 10 'durand 10))
  (define MP2 (micropay 'smith 10 'dupont 10 'durand 10))
  (define MP3 (micropay 'smith 10 'dupont 10 'durand 10))
  (define HOST1 Void)
  (define PR1 Void)
  (define PR2 Void)
  (define PR3 Void)
  (define GR1 Void)

  (place-on-heap MP1)

  (##inline-host-statement "
  // console.log('Mpay', @1@, @scm2host@(@1@));
  window.GLO = @glo@" MP1)


  (##inline-host-statement
   "globalThis.StateChannels.objs =
     { MP1: @1@, MP2: @2@, MP3: @3@ }"
   MP1 MP2 MP3)

  (def (call-method-using-string str obj . args)
    (apply mcall (string->symbol str) obj args))

(##inline-host-statement "
   window.StateChannels.cr = () => @async_call@(false, false, @2@, []);
    window.StateChannels.mcall = (meth, obj, ...args) => {
      const xargs = @host2scm@(args);
      return @async_call@(false, false, @1@,[@host2scm@(meth), obj, ...xargs])
    };" call-method-using-string cr)

 (def (property-value obj name)
   (def sym (if (symbol? name) name (string->symbol name)))
   (def val (: obj name))
   (if (unspecified? val) (method (typeof obj) sym)))


(def (doublewrap obj)
   (##inline-host-expression "@host2foreign@(@host2foreign@(@1@))" obj))


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
  (rexpr scm-type `(,@slots)))

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
   const scm = proc instanceof StateChannels.Rexpr ? proc.$scm : proc
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
   const scm = proc instanceof StateChannels.Rexpr ? proc.$scm : proc
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
ProcHost.prototype = Object.create(StateChannels.Rexpr.prototype);
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
ProcL.prototype = Object.create(StateChannels.Rexpr.prototype);
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
ProcGroupAndAttach.prototype = Object.create(StateChannels.Rexpr.prototype);
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
  (lstp)

(displayln "Current tg: "
           (thread-group->thread-list (current-thread-group))))

;(main)
