;;;; Copyright by The HDF Group.                                              
;;;; All rights reserved.
;;;;
;;;; This file is part of hdf5-cffi.
;;;; The full hdf5-cffi copyright notice, including terms governing
;;;; use, modification, and redistribution, is contained in the file COPYING,
;;;; which can be found at the root of the source code distribution tree.
;;;; If you do not have access to this file, you may request a copy from
;;;; help@hdfgroup.org.

;;; This example shows how to read and write a complex
;;; compound datatype to a dataset.  The program first writes
;;; complex compound structures to a dataset with a dataspace
;;; of DIM0, then closes the file.  Next, it reopens the file,
;;; reads back selected fields in the structure, and outputs
;;; them to the screen.

;;; Unlike the other datatype examples, in this example we
;;; save to the file using native datatypes to simplify the
;;; type definitions here.  To save using standard types you
;;; must manually calculate the sizes and offsets of compound
;;; types as shown in h5ex_t_cmpd.c, and convert enumerated
;;; values as shown in h5ex_t_enum.c.

;;; The datatype defined here consists of a compound
;;; containing a variable-length list of compound types, as
;;; well as a variable-length string, enumeration, double
;;;  array, object reference and region reference.  The nested
;;;  compound type contains an int, variable-length string and
;;;  two doubles.

;;; http://www.hdfgroup.org/ftp/HDF5/examples/examples-by-api/hdf5-examples/1_8/C/H5T/h5ex_t_cpxcmpd.c


#+sbcl(require 'asdf)
(asdf:operate 'asdf:load-op 'hdf5-cffi)

(in-package :hdf5)

(defparameter *FILE*    "h5ex_t_cpxcmpd.h5")
(defparameter *DATASET* "DS1")
(defparameter *DIM0*    2)
(defparameter *LENA*    4)
(defparameter *LENB*    1)

(cffi:defcstruct sensor-t
    "sensor_t"
  (serial-no   :int)
  (location    :string)
  (temperature :double)
  (pressure    :double))

(cffi:defcenum color-t
    "color_t"
  :RED
  :GREEN
  :BLUE)

(cffi:defcstruct vehicle-t
    "vehicle_t"
  (sensors        (:struct hvl-t))
  (name           :string)
  (color          color-t)
  (location       :double :count 3)
  (group          hobj-ref-t)
  (surveyed-areas (:struct hdset-reg-ref-t)))

(cffi:defcstruct rvehicle-t
    "rvehicle_t"
  (sensors (:struct hvl-t))
  (name    :string))

(cffi:with-foreign-objects
    ((dims 'hsize-t 1)
     (adims 'hsize-t 1)
     (adims2 'hsize-t 2)
     (start 'hsize-t 2)
     (count 'hsize-t 2)
     (coords 'hsize-t (* 3 2))
     (wdata  '(:struct vehicle-t) 2)
     (val    'color-t)
     (wdata2 :double (* 32 32)))

  (let*
      ((fapl (h5pcreate +H5P-FILE-ACCESS+))
       (file (prog2
		 (h5pset-fclose-degree fapl :H5F-CLOSE-STRONG)
		 (h5fcreate *FILE* +H5F-ACC-TRUNC+ +H5P-DEFAULT+ fapl)))
       (ptrA (cffi:foreign-alloc '(:struct sensor-t) :count *LENA*))
       (ptrB (cffi:foreign-alloc '(:struct sensor-t) :count *LENB*)))
  
    (unwind-protect

	 (progn
	   ;; create a dataset to use for region references
	   (dotimes (i 32)
	     (dotimes (j 32)
	       (setf (cffi:mem-aref wdata2 :double (+ (* i 32) j))
		     (+ 70.0d0
			(* 0.1d0 (- i 16.0d0))
			(* 0.1d0 (- j 16.0d0))))))
	   (let*
	       ((shape (prog2
			   (setf (cffi:mem-aref adims2 'hsize-t 0) 32
				 (cffi:mem-aref adims2 'hsize-t 1) 32)
			   (h5screate-simple 2 adims2 (cffi:null-pointer))))
		(dset (h5dcreate2 file "Ambient_Temperature"
				  +H5T-NATIVE-DOUBLE+ shape
				  +H5P-DEFAULT+ +H5P-DEFAULT+ +H5P-DEFAULT+)))
	     (h5dwrite dset +H5T-NATIVE-DOUBLE+ +H5S-ALL+ +H5S-ALL+
		       +H5P-DEFAULT+ wdata2)
	     (h5dclose dset)
	     (h5sclose shape))

	   ;; create groups to use for object references
	   (h5gclose (h5gcreate2 file "Land_Vehicles" +H5P-DEFAULT+
				 +H5P-DEFAULT+ +H5P-DEFAULT+))
	   (h5gclose (h5gcreate2 file "Air_Vehicles" +H5P-DEFAULT+
				 +H5P-DEFAULT+ +H5P-DEFAULT+))

	   ;; Initialize variable-length compound in the first data element.
	   (setf (cffi:foreign-slot-value
		  (cffi:foreign-slot-pointer
		   (cffi:mem-aptr wdata '(:struct vehicle-t) 0)
		   '(:struct vehicle-t) 'sensors)
		  '(:struct hvl-t) 'len) *LENA*)
	   (let*
	       ((ptr[0] (cffi:mem-aptr ptrA '(:struct sensor-t) 0))
		(ptr[1] (cffi:mem-aptr ptrA '(:struct sensor-t) 1))
		(ptr[2] (cffi:mem-aptr ptrA '(:struct sensor-t) 2))
		(ptr[3] (cffi:mem-aptr ptrA '(:struct sensor-t) 3)))
	     (cffi:with-foreign-slots
		 ((serial-no location temperature pressure)
		  ptr[0] (:struct sensor-t))
	       (setf serial-no 1153 location "Exterior (static)"
		     temperature 53.23d0 pressure 24.57d0))
	     (cffi:with-foreign-slots
		 ((serial-no location temperature pressure)
		  ptr[1] (:struct sensor-t))
	       (setf serial-no 1184 location "Intake"
		     temperature 55.12d0 pressure 22.95d0))
	     (cffi:with-foreign-slots
		 ((serial-no location temperature pressure)
		  ptr[2] (:struct sensor-t))
	       (setf serial-no 1027 location "Intake manifold"
		     temperature 103.55d0 pressure 31.23d0))
	     (cffi:with-foreign-slots
		 ((serial-no location temperature pressure)
		  ptr[3] (:struct sensor-t))
	       (setf serial-no 1313 location "Exhaust manifold"
		     temperature 1252.89d0 pressure 84.11d0)))
	   (setf (cffi:foreign-slot-value
		  (cffi:foreign-slot-pointer
		   (cffi:mem-aptr wdata '(:struct vehicle-t) 0)
		   '(:struct vehicle-t) 'sensors)
		  '(:struct hvl-t) 'p) ptrA)

	   ;; Initialize other fields in the first data element.
	   (let ((wdata[0] (cffi:mem-aptr wdata '(:struct vehicle-t) 0)))
	     (cffi:with-foreign-slots
		 ((name color location) wdata[0] (:struct vehicle-t))
	       (setf name "Airplane"
		     color :GREEN
		     (cffi:mem-aref location :double 0) -103234.21d0
	             (cffi:mem-aref location :double 1) 422638.78d0
		     (cffi:mem-aref location :double 2) 5996.43d0))
	     (h5rcreate (cffi:foreign-slot-pointer
			 wdata[0] '(:struct vehicle-t) 'group)
			file "Air_Vehicles" :H5R-OBJECT -1)	     
	     (let ((shape (prog2
			      (setf (cffi:mem-aref adims2 'hsize-t 0) 32
				    (cffi:mem-aref adims2 'hsize-t 1) 32)
			      (h5screate-simple 2 adims2 (cffi:null-pointer)))))
	       (h5sselect-elements shape :H5S-SELECT-SET 3 coords)
	       (h5rcreate (cffi:foreign-slot-pointer wdata[0]
			   '(:struct vehicle-t) 'surveyed-areas)
			  file "Ambient_Temperature" :H5R-DATASET-REGION shape)
	       (h5sclose shape)))

	   ;; Initialize variable-length compound in the second data element.
	   (setf (cffi:foreign-slot-value
		  (cffi:foreign-slot-pointer
		   (cffi:mem-aptr wdata '(:struct vehicle-t) 1)
		   '(:struct vehicle-t) 'sensors)
		  '(:struct hvl-t) 'len) *LENB*)
	   (let* ((ptr[0] (cffi:mem-aptr ptrB '(:struct sensor-t) 0)))
	     (cffi:with-foreign-slots
		 ((serial-no location temperature pressure)
		  ptr[0] (:struct sensor-t))
	       (setf serial-no 3244 location "Roof"
		     temperature 83.82d0 pressure 29.92d0)))
	   (setf (cffi:foreign-slot-value
		  (cffi:foreign-slot-pointer
		   (cffi:mem-aptr wdata '(:struct vehicle-t) 1)
		   '(:struct vehicle-t) 'sensors)
		  '(:struct hvl-t) 'p) ptrB)

	   ;; Initialize other fields in the second data element.
	   (let ((wdata[1] (cffi:mem-aptr wdata '(:struct vehicle-t) 1)))
	     (cffi:with-foreign-slots
		 ((name color location) wdata[1] (:struct vehicle-t))
	       (setf name "Automobile"
		     color :RED
		     (cffi:mem-aref location :double 0) 326734.36d0
	             (cffi:mem-aref location :double 1) 221568.23d0
		     (cffi:mem-aref location :double 2) 432.36d0))
	     (h5rcreate (cffi:foreign-slot-pointer
			 wdata[1] '(:struct vehicle-t) 'group)
			file "Land_Vehicles" :H5R-OBJECT -1)	     
	     (let ((shape (prog2
			      (setf (cffi:mem-aref adims2 'hsize-t 0) 32
				    (cffi:mem-aref adims2 'hsize-t 1) 32)
			      (h5screate-simple 2 adims2 (cffi:null-pointer)))))
	       (setf (cffi:mem-aref start 'hsize-t 0) 8
		     (cffi:mem-aref start 'hsize-t 1) 26
		     (cffi:mem-aref count 'hsize-t 0) 4
		     (cffi:mem-aref count 'hsize-t 1) 3)
	       (h5sselect-hyperslab shape :H5S-SELECT-SET
				    start (cffi:null-pointer)
				    count (cffi:null-pointer))
	       (h5rcreate (cffi:foreign-slot-pointer wdata[1]
			   '(:struct vehicle-t) 'surveyed-areas)
			  file "Ambient_Temperature" :H5R-DATASET-REGION shape)
	       (h5sclose shape)))

	   ;; Create variable-length string datatype.

	   ;; Create the nested compound datatype.

	   ;; Create the variable-length datatype.

	   ;; Create the enumerated datatype.

	   ;; Create the array datatype.

	   ;; Create the main compound datatype.

	   ;; Create dataspace. Setting maximum size to NULL sets the maximum
           ;; size to be the current size.

	   ;; Create the dataset and write the compound data to it.

	   )

      (cffi:foreign-free ptrB)
      (cffi:foreign-free ptrA)
      (h5fclose file)
      (h5pclose fapl))))

#+sbcl(sb-ext:quit)
