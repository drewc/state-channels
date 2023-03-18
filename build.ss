#!/usr/bin/env gxi
(import :std/make)

 ;; the source directory anchor
 (def srcdir
  (path-normalize (path-directory (this-source-file))))

(if (equal? srcdir (current-directory)) #t
    (begin
      (displayln "Going into " srcdir " for building state-channels"
                 " from " (initial-current-directory))
      (current-directory srcdir)))


;; the library module build specification
(def lib-build-spec '("src/socks" "examples/mp1" "examples/mp1_1" "exe"))
(let src ((fs (directory-files "src")))
  ;; (displayln "Have " (length fs) " files in src")
  (if (not (null? fs))
    (let ((f (car fs)))
      (displayln "f:" f (equal? f "clish_prg.ss") )
      (if (and (equal? (path-extension f) ".ss")
               (not (equal? f "clish.ss"))
               (not (equal? f "scm2js.ss"))
               (not (equal? f "clish_prg.ss")))
         (set! lib-build-spec
                 (cons (path-expand (path-strip-extension f)
                                    "src/")
                       lib-build-spec)))
               (src (cdr fs)))))


(def (make-lib)
  ;; (displayln "Making Library from:" lib-build-spec)
(make srcdir: srcdir
      bindir: srcdir
      libdir: (path-expand "lib/" srcdir)
      optimize: #t
      debug: 'src             ; enable debugger introspection for library modules
      static: #t              ; generate static compilation artifacts; required!
     ;; prefix: "mukn/state-channels/
      ;; build-deps: "build-deps" ; this value is the default
      lib-build-spec))


(def bin-build-spec '((static-exe: "exe")))


(def (make-bin)
  (def libdir (path-expand "lib/" srcdir))
  (add-load-path libdir)
 ;; this action builds the static executables -- no debug introspection
   (make srcdir: srcdir
         bindir: (path-expand "bin/" srcdir)
         libdir: libdir
         verbose: 5
         optimize: #f
         debug: #f               ; no debug bloat for executables
         static: #t              ; generate static compilation artifacts; required!
         build-deps: "build-deps-bin" ; importantly, pick a file that differs from above
         bin-build-spec))

(def js-bin-build-spec
  '((static-exe: "exe"
                 "-verbose"
                 "-target" "js" )))

(def (compile-static-exe mod opts settings)
  (def srcpath (source-path mod ".ss" settings))
  (def binpath (binary-path mod opts settings))
  (def gsc-opts (compile-exe-gsc-opts opts))
  (def gxc-opts
    [invoke-gsc: #t
                 output-file: binpath
                 verbose: (settings-verbose>=? settings 9)
                 debug: (settings-static-debug settings)
                 (when/list gsc-opts [gsc-options: gsc-opts]) ...])

  (message "... compile static js? exe " mod " -> " gxc-opts)
  (gxc-compile mod gsc-opts (make-settings-static settings))
  (message "... compile static exe " mod " -> " binpath)
  (gxc#compile-static-exe srcpath gxc-opts))

(set! std/make#compile-static-exe compile-static-exe)
(def (make-js-bin)
  (def libdir (path-expand "lib/" srcdir))
  (add-load-path libdir)
 ;; this action builds the static executables -- no debug introspection
   (make srcdir: srcdir
         bindir: (path-expand "js/bin/" srcdir)
         libdir: libdir
         verbose: 5
         optimize: #f
         debug: #f               ; no debug bloat for executables
         static: #t              ; generate static compilation artifacts; required!
         build-deps: "build-deps-js-bin" ; importantly, pick a file that differs from above
         js-bin-build-spec))

(def (main . args)
  (shell-command "./build gerbil")
  (shell-command "backends/build filesocks_dummy")
  (make-lib)
  (make-bin)
  (make-js-bin))
