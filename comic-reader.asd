(in-package #:cl-user)
(asdf:defsystem #:comic-reader
  :defsystem-depends-on (:radiance :lass)
  :class "radiance:module"
  :components ((:file "module")
               (:file "db")
               (:file "comic")
               (:file "admin"))
  :depends-on ((:interface :database)
               (:interface :data-model)
               (:interface :user)
               (:interface :admin)
               :alexandria
               :r-clip
               :i-json
               :cl-ppcre
               :ratify))
