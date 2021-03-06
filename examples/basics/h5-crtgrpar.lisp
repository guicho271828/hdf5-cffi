;;;; Copyright by The HDF Group.
;;;; All rights reserved.
;;;;
;;;; This file is part of hdf5-cffi.
;;;; The full hdf5-cffi copyright notice, including terms governing
;;;; use, modification, and redistribution, is contained in the file COPYING,
;;;; which can be found at the root of the source code distribution tree.
;;;; If you do not have access to this file, you may request a copy from
;;;; help@hdfgroup.org.

;;; This example illustrates the creation of groups using absolute and 
;;; relative names.
;;; http://www.hdfgroup.org/ftp/HDF5/current/src/unpacked/examples/h5_crtgrpar.c

#+sbcl(require 'asdf)
(asdf:operate 'asdf:load-op 'hdf5-cffi)
(asdf:operate 'asdf:load-op 'hdf5-examples)

(in-package :hdf5)

(defparameter *FILE* "groups.h5")

(let* ((fapl (h5pcreate +H5P-FILE-ACCESS+))
     (file (prog2
	       (h5pset-fclose-degree fapl :H5F-CLOSE-STRONG)
	       (h5fcreate *FILE* +H5F-ACC-TRUNC+ +H5P-DEFAULT+ fapl))))
  (unwind-protect
       (let* ((g1 (h5gcreate2 file "/MyGroup"
			      +H5P-DEFAULT+ +H5P-DEFAULT+ +H5P-DEFAULT+))
	      (g2 (h5gcreate2 file "/MyGroup/Group_A"
			      +H5P-DEFAULT+ +H5P-DEFAULT+ +H5P-DEFAULT+))
	      (g3 (h5gcreate2 g1 "Group_B"
			      +H5P-DEFAULT+ +H5P-DEFAULT+ +H5P-DEFAULT+)))
	 (h5ex:close-handles (list g3 g2 g1)))
    (h5ex:close-handles (list file fapl))))
