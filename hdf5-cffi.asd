;;;; hdf5-cffi.asd

(asdf:defsystem #:hdf5-cffi
  :serial t
  :description "hdf5-cffi is a CFFI wrapper for the HDF5 library."
  :author "Gerd Heber <leberecht@beingandti.me>"
  :license "BSD"
  :components ((:file "package")
               (:file "hdf5-cffi")
               (:file "h5")
	       (:file "h5i")
	       (:file "h5f")
	       (:file "h5t")
	       (:file "h5l")
	       (:file "h5o")
	       (:file "h5s")
	       (:file "h5d")
	       (:file "h5g")
	       (:file "h5a")
	       (:file "h5r")
	       (:file "h5p"))
  :depends-on ("cffi"))

